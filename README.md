# Concepto Básico del Proyecto
Este proyecto crea un exchange descentralizado (DEX) simple que permite intercambiar dos tokens personalizados (TokenA y TokenB) usando un pool de liquidez. Todo se ejecuta en Remix IDE, sin necesidad de configuraciones complejas.

# Componentes Clave y su Lógica
## 1. Los Tokens (TokenA y TokenB)
### Qué son:

Son tokens ERC-20 estándar con funcionalidad extra

Cada uno tiene su propio nombre y símbolo

Solo el creador (owner) puede producir nuevos tokens (mint)

### Para qué sirven:

TokenA y TokenB son las dos monedas que podrás intercambiar en el DEX

Representan los activos básicos del sistema

## 2. El SimpleDEX
### Cómo funciona:

### Pool de Liquidez: Un fondo común donde se depositan ambos tokens

### Fórmula Matemática: Usa (x * y = k) para determinar precios automáticamente

x = cantidad de TokenA en el pool

y = cantidad de TokenB en el pool

k = valor constante que mantiene el equilibrio

### Mecanismo de Swaps:

Cuando alguien cambia TokenA por TokenB:

Deposita TokenA en el pool (aumenta x)

Recibe TokenB del pool (disminuye y)

El precio se ajusta automáticamente según la fórmula

# Flujo Completo en Remix
## Creación de Tokens:

Despliegas TokenA y TokenB (cada uno con tu dirección como dueño)

Les das "mint" para crear tus tokens iniciales

## Configuración del DEX:

Despliegas SimpleDEX indicando las direcciones de ambos tokens

Apruebas al DEX para manejar tus tokens

## Añadir Liquidez:

Depositas cantidades iniciales de ambos tokens en el pool

Esto establece el precio inicial (ej. 1 TokenA = 2 TokenB)

## Hacer Swaps:

Cualquier usuario puede intercambiar tokens

El sistema calcula automáticamente cuánto recibirás basado en las reservas actuales

## Retirar Liquidez:

Como owner, puedes retirar tu participación del pool

Recibes ambos tokens en proporción a lo depositado

# Ventajas de este Diseño
Sistema Autoregulado: Los precios se ajustan solos según la oferta/demanda

Transparente: Todas las operaciones son verificables en la blockchain

Sin Intermediarios: Los usuarios intercambian directamente con el contrato

Simple pero Funcional: Ideal para entender los conceptos básicos de DeFi
