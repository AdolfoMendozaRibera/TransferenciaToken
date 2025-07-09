// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleDEX is Ownable {
    IERC20 public tokenA;
    IERC20 public tokenB;
    
    uint256 public reserveA;
    uint256 public reserveB;
    
    // Eventos
    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB);
    event SwapAforB(address indexed user, uint256 amountAIn, uint256 amountBOut);
    event SwapBforA(address indexed user, uint256 amountBIn, uint256 amountAOut);

    constructor(address _tokenA, address _tokenB) Ownable(msg.sender) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    // Añade la liquidez al pool
    function addLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(amountA > 0 && amountB > 0, "Amounts must be greater than 0");
        
        // Transfiere los tokens al contrato
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);
        
        // Actualiza las reservas
        reserveA += amountA;
        reserveB += amountB;
        
        emit LiquidityAdded(msg.sender, amountA, amountB);
    }

    // Intercambia el TokenA por TokenB
    function swapAforB(uint256 amountAIn) external {
        require(amountAIn > 0, "Amount must be greater than 0");
        require(reserveA > 0 && reserveB > 0, "Insufficient liquidity");
        
        // Calcula la cantidad de TokenB a entregar
        uint256 amountBOut = (amountAIn * reserveB) / (reserveA + amountAIn);
        uint256 amountBOutWithFee = (amountBOut * 997) / 1000; // 0.3% fee
        
        require(amountBOutWithFee > 0, "Insufficient output amount");
        require(tokenB.balanceOf(address(this)) >= amountBOutWithFee, "Insufficient TokenB in pool");
        
        // Transfiere el TokenA del usuario al contrato
        tokenA.transferFrom(msg.sender, address(this), amountAIn);
        
        // Transfiere el TokenB al usuario
        tokenB.transfer(msg.sender, amountBOutWithFee);
        
        // Actualiza las reservas
        reserveA += amountAIn;
        reserveB -= amountBOutWithFee;
        
        emit SwapAforB(msg.sender, amountAIn, amountBOutWithFee);
    }

    // Intercambian los TokenB por TokenA
    function swapBforA(uint256 amountBIn) external {
        require(amountBIn > 0, "Amount must be greater than 0");
        require(reserveA > 0 && reserveB > 0, "Insufficient liquidity");
        
        // Calcula la cantidad de TokenA a entregar 
        uint256 amountAOut = (amountBIn * reserveA) / (reserveB + amountBIn);
        uint256 amountAOutWithFee = (amountAOut * 997) / 1000; // 0.3% fee
        
        require(amountAOutWithFee > 0, "Insufficient output amount");
        require(tokenA.balanceOf(address(this)) >= amountAOutWithFee, "Insufficient TokenA in pool");
        
        // Transfiere los TokenB del usuario al contrato
        tokenB.transferFrom(msg.sender, address(this), amountBIn);
        
        // Transfiere el TokenA al usuario
        tokenA.transfer(msg.sender, amountAOutWithFee);
        
        // Actualiza las reservas
        reserveB += amountBIn;
        reserveA -= amountAOutWithFee;
        
        emit SwapBforA(msg.sender, amountBIn, amountAOutWithFee);
    }

    // Retira la liquidez del pool
    function removeLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(amountA > 0 && amountB > 0, "Amounts must be greater than 0");
        require(reserveA >= amountA && reserveB >= amountB, "Insufficient reserves");
        
        // Transferiere tokens al owner
        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);
        
        // Actualiza las reservas
        reserveA -= amountA;
        reserveB -= amountB;
        
        emit LiquidityRemoved(msg.sender, amountA, amountB);
    }

    // Obtiene el precio de un token en terminos del otro
    function getPrice(address _token) external view returns (uint256) {
        require(_token == address(tokenA) || _token == address(tokenB), "Invalid token");
        
        if (_token == address(tokenA)) {
            return (reserveB * 1e18) / reserveA; // Precio de A en terminos de B
        } else {
            return (reserveA * 1e18) / reserveB; // Precio de B en terminos de A
        }
    }
}