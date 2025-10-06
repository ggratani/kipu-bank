
## Cómo desplegar con Remix (Sepolia)

**Requisitos**:
- **MetaMask** configurado en **Sepolia** (con ETH de faucet).
- Navegador con acceso a **https://remix.ethereum.org**.

**Pasos**:
1. Abrí **https://remix.ethereum.org**.
2. En **File Explorer** → **Create New File** → `contracts/KipuBank.sol`.
3. El contenido del contrato esta en `KipuBank.sol` (este repo lo contiene en `/contracts`).
4. Abrí **Solidity Compiler**:
   - Versión: **0.8.24**.
   - **Optimizer**: *No* (para simplificar verificación), o **Yes** con *runs=200* si preferís.
   - Clic en **Compile KipuBank.sol**.
5. Abrí **Deploy & Run Transactions**:
   - **Environment**: **Injected Provider – MetaMask**.
   - Red: **Sepolia**.
   - **Contract**: `KipuBank - contracts/KipuBank.sol`.
   - **Constructor args** (en **wei**, enteros):
     - `withdrawalThreshold` = `50000000000000000`  (0.05 ETH)
     - `bankCap`            = `5000000000000000000` (5 ETH)
   - Clic **Deploy** y confirmá en MetaMask.
6. Copiá la **dirección del contrato** (aparece en Remix y en el explorer de la tx).

> Si querés otros valores, convertí ETH→wei (1 ETH = 1e18 wei).  
> Ejemplo: 0.2 ETH → `200000000000000000`.

---

## Verificación del código en Etherscan

1. Abrí tu address en **https://sepolia.etherscan.io**.
2. Pestaña **Contract** → **Verify and Publish**.
3. **Compiler**: **0.8.24** (exactamente la usada en Remix).
4. **License**: **MIT**.
5. **Optimization**:
   - Marca **No** si no usaste optimizer en Remix.
   - Marca **Yes** y poné **200** runs si lo activaste al compilar.
6. Modo: **Single file** y pegá tu `KipuBank.sol`.
7. **Constructor arguments**: pegá **exactamente**:
   - `50000000000000000`
   - `5000000000000000000`
8. Confirmá. Si todo coincide, el contrato queda **Verified**.

---

## Cómo interactuar (Remix)

Con el contrato desplegado, en **Deployed Contracts** (Remix):

- **Depositar**  
  En el campo **Value** (arriba de los botones), poné por ejemplo `0.02 ether` o `20000000000000000` (wei).  
  Clic en **deposit()** → confirmá en MetaMask → mirá el evento `Deposited`.

- **Consultar saldo**  
  `vaultOf(<tuAddress>)` → devuelve el saldo en **wei**.

- **Retirar**  
  `withdraw(<amountWei>)` cuidando:
  - `amountWei` > 0
  - `amountWei` ≤ `WITHDRAWAL_THRESHOLD` (0.05 ETH por nuestra config)
  - `amountWei` ≤ tu saldo (`vaultOf`)
  
  Ejemplo: `withdraw(10000000000000000)` (0.01 ETH).  
  Mirá el evento `Withdrawn`.

**Errores esperados**:
- `ExceedsThreshold`: si intentás retirar > 0.05 ETH (con esta config).
- `InsufficientFunds`: si el monto supera tu saldo.
- `ExceedsBankCap`: si un depósito haría superar el tope global.
- `ZeroAmount`: si pasás 0 como monto (withdraw) o intentás depositar 0.
- `Reentrancy`: protección si hay intento de reingreso.

---

## Dirección desplegada
- Red: Sepolia
- Address: 0xaa8ca49e91216d04ed51587232052d3f6bf4c830
- Verificado: https://testnet.routescan.io/address/0xaa8ca49e91216d04ed51587232052d3f6bf4c830/contract/11155111/code

## Parámetros de constructor (wei)
- withdrawalThreshold: 50000000000000000   # 0.05 ETH
- bankCap:            5000000000000000000  # 5 ETH

## Compilación/Verificación
- Solidity: 0.8.24
- Optimizer: No  (usa Yes + runs=200 si lo activaste en Remix)


## Licencia

**MIT**
