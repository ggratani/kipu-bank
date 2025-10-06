// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title KipuBank - Bóvedas personales con tope global y umbral por retiro
/// @notice Permite a los usuarios depositar y retirar ETH con límites seguros.
/// @dev Sigue patrón checks-effects-interactions, usa errores personalizados y eventos.
/// @custom:security-contact tu-email@ejemplo.com
contract KipuBank {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Monto cero no permitido.
    error ZeroAmount();

    /// @notice Depósito excede el tope global del banco.
    /// @param cap Tope global configurado al desplegar.
    /// @param attempted Suma total luego del intento.
    error ExceedsBankCap(uint256 cap, uint256 attempted);

    /// @notice Retiro excede el umbral por transacción.
    /// @param threshold Umbral inmutable.
    /// @param attempted Monto solicitado.
    error ExceedsThreshold(uint256 threshold, uint256 attempted);

    /// @notice Fondos insuficientes en la bóveda del usuario.
    /// @param balance Saldo disponible.
    /// @param attempted Monto solicitado.
    error InsufficientFunds(uint256 balance, uint256 attempted);

    /// @notice Falla en la transferencia nativa.
    error TransferFailed();

    /// @notice Reingreso detectado.
    error Reentrancy();

    /*//////////////////////////////////////////////////////////////
                           EVENTS (LOGGING)
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted on successful deposit.
    /// @param user Dirección del depositante.
    /// @param amount Monto depositado en wei.
    /// @param newUserBalance Saldo del usuario luego del depósito.
    /// @param totalBankBalance Saldo total del banco luego del depósito.
    event Deposited(address indexed user, uint256 amount, uint256 newUserBalance, uint256 totalBankBalance);

    /// @notice Emitted on successful withdrawal.
    /// @param user Dirección del que retira.
    /// @param amount Monto retirado en wei.
    /// @param newUserBalance Saldo del usuario luego del retiro.
    /// @param totalBankBalance Saldo total del banco luego del retiro.
    event Withdrawn(address indexed user, uint256 amount, uint256 newUserBalance, uint256 totalBankBalance);

    /*//////////////////////////////////////////////////////////////
                        STATE (STORAGE / CONSTANTS)
    //////////////////////////////////////////////////////////////*/

    /// @notice Umbral máximo por retiro individual (inmutable).
    /// @dev Fijado en el constructor.
    uint256 public immutable WITHDRAWAL_THRESHOLD;

    /// @notice Tope global de depósitos del banco (inmutable).
    /// @dev Fijado en el constructor.
    uint256 public immutable BANK_CAP;

    /// @notice Saldo por usuario.
    mapping(address => uint256) private _vault;

    /// @notice Contador global de depósitos exitosos.
    uint256 public depositsCount;

    /// @notice Contador global de retiros exitosos.
    uint256 public withdrawalsCount;

    /// @notice Suma de todos los saldos del banco.
    uint256 public totalBankBalance;

    /// @dev Guard simple anti-reentrancy.
    bool private _entered;

    /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @param withdrawalThreshold Umbral máximo por retiro (wei).
    /// @param bankCap Tope global del banco (wei).
    constructor(uint256 withdrawalThreshold, uint256 bankCap) {
        if (withdrawalThreshold == 0 || bankCap == 0) revert ZeroAmount();
        WITHDRAWAL_THRESHOLD = withdrawalThreshold;
        BANK_CAP = bankCap;
    }

    /*//////////////////////////////////////////////////////////////
                               MODIFIER
    //////////////////////////////////////////////////////////////*/

    /// @dev Simple nonReentrant sin dependencias externas.
    modifier nonReentrant() {
        if (_entered) revert Reentrancy();
        _entered = true;
        _;
        _entered = false;
    }

    /*//////////////////////////////////////////////////////////////
                              EXTERNAL API
    //////////////////////////////////////////////////////////////*/

    /// @notice Depósitá ETH en tu bóveda personal.
    /// @dev CEI: (checks) -> (effects) -> (interactions). Emite evento.
    /// @custom:oz-usage No usa transfer()/send(); usa call{value:...} con chequeo.
    function deposit() external payable nonReentrant {
        if (msg.value == 0) revert ZeroAmount();

        // CHECKS
        uint256 newTotal = totalBankBalance + msg.value;
        if (newTotal > BANK_CAP) revert ExceedsBankCap(BANK_CAP, newTotal);

        // EFFECTS
        _vault[msg.sender] += msg.value;
        totalBankBalance = newTotal;
        unchecked {
            depositsCount += 1;
        }

        // INTERACTIONS: no hay envío saliente aquí.
        emit Deposited(msg.sender, msg.value, _vault[msg.sender], totalBankBalance);
    }

    /// @notice Retirá hasta el umbral por transacción, sin exceder tu saldo.
    /// @param amount Monto a retirar en wei.
    /// @dev Usa call con verificación. Emite evento.
    function withdraw(uint256 amount) external nonReentrant {
        if (amount == 0) revert ZeroAmount();
        if (amount > WITHDRAWAL_THRESHOLD) revert ExceedsThreshold(WITHDRAWAL_THRESHOLD, amount);

        uint256 bal = _vault[msg.sender];
        if (amount > bal) revert InsufficientFunds(bal, amount);

        // CHECKS pasados. EFFECTS primero:
        _vault[msg.sender] = bal - amount;
        totalBankBalance -= amount;
        unchecked {
            withdrawalsCount += 1;
        }

        // INTERACTIONS (después de effects):
        _safeTransfer(payable(msg.sender), amount);

        emit Withdrawn(msg.sender, amount, _vault[msg.sender], totalBankBalance);
    }

    /// @notice Leé el saldo de la bóveda de una cuenta.
    /// @param account Dirección a consultar.
    /// @return balance Saldo en wei.
    function vaultOf(address account) external view returns (uint256 balance) {
        return _vault[account];
    }

    /*//////////////////////////////////////////////////////////////
                               INTERNALS
    //////////////////////////////////////////////////////////////*/

    /// @dev Función privada para transferir ETH de forma segura.
    function _safeTransfer(address payable to, uint256 amount) private {
        (bool ok, ) = to.call{value: amount}("");
        if (!ok) revert TransferFailed();
    }
}
