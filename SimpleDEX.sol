// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleDEX is Ownable {

    // Tokens que se manejaran
    IERC20 public tokenA;
    IERC20 public tokenB;
    
    // Las reservas de cada token en el pool
    uint256 public reserveA;
    uint256 public reserveB;
    
    uint256 public totalLiquidity; // Liquidez total del pool
    mapping(address => uint256) public liquidity; // Liquidez por proveedor
    
    // Eventos que registran acciones importantes
    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidityMinted);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidityBurned);
    event SwapAforB(address indexed user, uint256 amountAIn, uint256 amountBOut);
    event SwapBforA(address indexed user, uint256 amountBIn, uint256 amountAOut);

    /**
     Constructor que inicializa el DEX con los dos tokens a intercambiar
     _tokenA: Direccion del primer token 
     _tokenB: Direccion del segundo token
     */
    constructor(address _tokenA, address _tokenB) Ownable(msg.sender) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    /*
     Añade liquidez al pool. Solo el owner puede llamar esta función
     amountA: Cantidad de TokenA a depositar
     amountB: Cantidad de TokenB a depositar
     */
    function addLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(amountA > 0 && amountB > 0, "Amounts must be greater than 0");
        
        // Si ya hay liquidez, verifica que las nuevas cantidades mantengan la proporcion
        if (totalLiquidity > 0) {
            uint256 expectedAmountB = (amountA * reserveB) / reserveA;
            require(amountB >= expectedAmountB, "Incorrect token ratio");
            if (amountB > expectedAmountB) {
                amountB = expectedAmountB; 
            }
        }
        
        // Transfiere los tokens al contrato
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);
        
        // Calcula los tokens de liquidez a mintear
        uint256 liquidityMinted;
        if (totalLiquidity == 0) {
            liquidityMinted = sqrt(amountA * amountB);
        } else {
            liquidityMinted = (amountA * totalLiquidity) / reserveA;
        }
        
        // Actualiza las reservas y la liquidez
        reserveA += amountA;
        reserveB += amountB;
        totalLiquidity += liquidityMinted;
        liquidity[msg.sender] += liquidityMinted;
        
        emit LiquidityAdded(msg.sender, amountA, amountB, liquidityMinted);
    }

    /*
     Intercambia TokenA por TokenB
     amountAIn: Cantidad de TokenA a intercambiar
     */
    function swapAforB(uint256 amountAIn) external {
        require(amountAIn > 0, "Amount must be greater than 0");
        require(reserveA > 0 && reserveB > 0, "Insufficient liquidity");
        
        // Aplica el fee del 0.3% 
        uint256 amountAInWithFee = (amountAIn * 997) / 1000;
        
        // (formula x*y=k)
        uint256 amountBOut = (amountAInWithFee * reserveB) / (reserveA + amountAInWithFee);
        
        require(amountBOut > 0, "Insufficient output amount");
        
        // Transfiere los tokens
        tokenA.transferFrom(msg.sender, address(this), amountAIn);
        tokenB.transfer(msg.sender, amountBOut);
        
        // Actualiza las reservas
        reserveA += amountAIn;
        reserveB -= amountBOut;
        
        emit SwapAforB(msg.sender, amountAIn, amountBOut);
    }

    /*
      Intercambia TokenB por TokenA
       amountBIn: Cantidad de TokenB a intercambiar
     */
    function swapBforA(uint256 amountBIn) external {
        require(amountBIn > 0, "Amount must be greater than 0");
        require(reserveA > 0 && reserveB > 0, "Insufficient liquidity");
        
        // Aplica fee del 0.3%
        uint256 amountBInWithFee = (amountBIn * 997) / 1000;
        
        // Calcular cantidad de TokenA a dar
        uint256 amountAOut = (amountBInWithFee * reserveA) / (reserveB + amountBInWithFee);
        
        require(amountAOut > 0, "Insufficient output amount");
        
        // Transfiere tokens
        tokenB.transferFrom(msg.sender, address(this), amountBIn);
        tokenA.transfer(msg.sender, amountAOut);
        
        // Actualiza las reservas
        reserveB += amountBIn;
        reserveA -= amountAOut;
        
        emit SwapBforA(msg.sender, amountBIn, amountAOut);
    }

    /*
      Retira liquidez del pool, solo el owner(dueño) puede llamar esta funcion
       liquidityToBurn: Cantidad de tokens LP a quemar
     */
    function removeLiquidity(uint256 liquidityToBurn) external onlyOwner {
        require(liquidityToBurn > 0, "Amount must be greater than 0");
        require(liquidity[msg.sender] >= liquidityToBurn, "Insufficient liquidity");
        
        // Calcula las cantidades proporcionales a retirar
        uint256 amountA = (liquidityToBurn * reserveA) / totalLiquidity;
        uint256 amountB = (liquidityToBurn * reserveB) / totalLiquidity;
        
        // Transfiere tokens al owner (dueño)
        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);
        
        // Actualiza las reservas y liquidez
        reserveA -= amountA;
        reserveB -= amountB;
        totalLiquidity -= liquidityToBurn;
        liquidity[msg.sender] -= liquidityToBurn;
        
        emit LiquidityRemoved(msg.sender, amountA, amountB, liquidityToBurn);
    }

    /*
      Obtiene el precio de un token en terminos del otro
      _token Direccion del token a consultar (TokenA o TokenB)
     */
    function getPrice(address _token) external view returns (uint256) {
        require(_token == address(tokenA) || _token == address(tokenB), "Invalid token");
        
        if (_token == address(tokenA)) {
            // Precio de A en terminos de B (cantidad de B por 1 A)
            return (reserveB * 10**18) / reserveA;
        } else {
            // Precio de B en terminos de A (cantidad de A por 1 B)
            return (reserveA * 10**18) / reserveB;
        }
    }
    
    /*
       Función interna para calcular raiz cuadrada (para el cálculo inicial de liquidez)
        y: Numero al que calcular la raiz
     */
    function sqrt(uint256 y) private pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
