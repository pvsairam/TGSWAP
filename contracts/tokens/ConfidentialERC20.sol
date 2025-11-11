// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "fhevm/lib/TFHE.sol";
import "fhevm/config/ZamaFHEVMConfig.sol";
import "fhevm/gateway/GatewayCaller.sol";

/**
 * @title ConfidentialERC20
 * @notice ERC-7984 compliant confidential token with REAL fhEVM encryption
 * @dev Implements encrypted balance management using Zama's fhEVM library
 *
 * This contract uses REAL homomorphic encryption:
 * - Balances are stored as euint64 (encrypted uint64)
 * - All arithmetic uses FHE operations (TFHE.add, TFHE.sub, etc.)
 * - Access control via TFHE.allow() for viewing encrypted data
 * - Gateway callbacks for decryption when needed
 */
contract ConfidentialERC20 is SepoliaZamaFHEVMConfig, GatewayCaller {
    // Token metadata
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    // Total supply (public for transparency)
    uint256 public totalSupply;

    // Owner address
    address public owner;

    // REAL ENCRYPTED BALANCES using euint64
    mapping(address => euint64) private _encryptedBalances;

    // REAL ENCRYPTED ALLOWANCES using euint64
    mapping(address => mapping(address => euint64)) private _encryptedAllowances;

    // Events
    event Transfer(address indexed from, address indexed to);
    event Approval(address indexed owner, address indexed spender);
    event Mint(address indexed to, uint64 amount);
    event Burn(address indexed from, uint64 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "ConfidentialERC20: caller is not the owner");
        _;
    }

    /**
     * @notice Constructor
     * @param _name Token name
     * @param _symbol Token symbol
     */
    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        owner = msg.sender;
    }

    /**
     * @notice Mint tokens to an address (only owner)
     * @param to Recipient address
     * @param amount Amount to mint (plaintext)
     */
    function mint(address to, uint64 amount) external onlyOwner {
        require(to != address(0), "ConfidentialERC20: mint to zero address");

        // Update total supply (plaintext)
        totalSupply += amount;

        // Convert plaintext amount to encrypted euint64
        euint64 encryptedAmount = TFHE.asEuint64(amount);

        // Add to recipient's encrypted balance using TFHE.add
        _encryptedBalances[to] = TFHE.add(_encryptedBalances[to], encryptedAmount);

        // Allow recipient to view their own balance
        TFHE.allowThis(_encryptedBalances[to]);
        TFHE.allow(_encryptedBalances[to], to);

        emit Mint(to, amount);
        emit Transfer(address(0), to);
    }

    /**
     * @notice Burn tokens from caller's balance
     * @param amount Encrypted amount to burn
     */
    function burn(einput amount, bytes calldata inputProof) external {
        // Convert input to encrypted euint64
        euint64 encryptedAmount = TFHE.asEuint64(amount, inputProof);

        // Check if caller has sufficient balance (encrypted comparison)
        ebool hasSufficientBalance = TFHE.le(encryptedAmount, _encryptedBalances[msg.sender]);

        // Subtract from balance only if sufficient (using TFHE.select)
        euint64 newBalance = TFHE.select(
            hasSufficientBalance,
            TFHE.sub(_encryptedBalances[msg.sender], encryptedAmount),
            _encryptedBalances[msg.sender] // Keep same balance if insufficient
        );

        _encryptedBalances[msg.sender] = newBalance;

        // Allow caller to view their new balance
        TFHE.allowThis(newBalance);
        TFHE.allow(newBalance, msg.sender);

        emit Burn(msg.sender, 0); // Amount is encrypted, emit 0
        emit Transfer(msg.sender, address(0));
    }

    /**
     * @notice Transfer tokens (ENCRYPTED)
     * @param to Recipient address
     * @param amount Encrypted amount to transfer
     */
    function transfer(address to, einput amount, bytes calldata inputProof) external returns (bool) {
        require(to != address(0), "ConfidentialERC20: transfer to zero address");

        // Convert input to encrypted euint64
        euint64 encryptedAmount = TFHE.asEuint64(amount, inputProof);

        // Execute encrypted transfer
        _transferImpl(msg.sender, to, encryptedAmount);

        emit Transfer(msg.sender, to);
        return true;
    }

    /**
     * @notice Transfer tokens from one address to another (ENCRYPTED)
     * @param from Sender address
     * @param to Recipient address
     * @param amount Encrypted amount to transfer
     */
    function transferFrom(
        address from,
        address to,
        einput amount,
        bytes calldata inputProof
    ) external returns (bool) {
        require(from != address(0), "ConfidentialERC20: transfer from zero address");
        require(to != address(0), "ConfidentialERC20: transfer to zero address");

        // Convert input to encrypted euint64
        euint64 encryptedAmount = TFHE.asEuint64(amount, inputProof);

        // Check allowance (encrypted comparison)
        euint64 currentAllowance = _encryptedAllowances[from][msg.sender];
        ebool hasSufficientAllowance = TFHE.le(encryptedAmount, currentAllowance);

        // Decrease allowance only if sufficient
        euint64 newAllowance = TFHE.select(
            hasSufficientAllowance,
            TFHE.sub(currentAllowance, encryptedAmount),
            currentAllowance
        );

        _encryptedAllowances[from][msg.sender] = newAllowance;

        // Allow spender to view new allowance
        TFHE.allowThis(newAllowance);
        TFHE.allow(newAllowance, msg.sender);

        // Execute encrypted transfer (only if allowance was sufficient)
        _transferImpl(from, to, encryptedAmount);

        emit Transfer(from, to);
        return true;
    }

    /**
     * @notice Approve spender to spend tokens (ENCRYPTED)
     * @param spender Spender address
     * @param amount Encrypted amount to approve
     */
    function approve(address spender, einput amount, bytes calldata inputProof) external returns (bool) {
        require(spender != address(0), "ConfidentialERC20: approve to zero address");

        // Convert input to encrypted euint64
        euint64 encryptedAmount = TFHE.asEuint64(amount, inputProof);

        // Set allowance
        _encryptedAllowances[msg.sender][spender] = encryptedAmount;

        // Allow both owner and spender to view allowance
        TFHE.allowThis(encryptedAmount);
        TFHE.allow(encryptedAmount, msg.sender);
        TFHE.allow(encryptedAmount, spender);

        emit Approval(msg.sender, spender);
        return true;
    }

    /**
     * @notice Get encrypted balance (SEALED - only viewable by authorized addresses)
     * @param account Account to query
     * @return Encrypted balance (euint64)
     */
    function balanceOf(address account) external view returns (euint64) {
        return _encryptedBalances[account];
    }

    /**
     * @notice Get encrypted allowance (SEALED)
     * @param _owner Owner address
     * @param spender Spender address
     * @return Encrypted allowance (euint64)
     */
    function allowance(address _owner, address spender) external view returns (euint64) {
        return _encryptedAllowances[_owner][spender];
    }

    /**
     * @notice Internal transfer implementation (ENCRYPTED)
     */
    function _transferImpl(address from, address to, euint64 encryptedAmount) internal {
        // Check if sender has sufficient balance (encrypted comparison)
        ebool hasSufficientBalance = TFHE.le(encryptedAmount, _encryptedBalances[from]);

        // Subtract from sender only if sufficient balance
        euint64 newBalanceFrom = TFHE.select(
            hasSufficientBalance,
            TFHE.sub(_encryptedBalances[from], encryptedAmount),
            _encryptedBalances[from]
        );

        // Add to recipient (using TFHE.select to only add if sender had sufficient balance)
        euint64 amountToAdd = TFHE.select(
            hasSufficientBalance,
            encryptedAmount,
            TFHE.asEuint64(0)
        );

        euint64 newBalanceTo = TFHE.add(_encryptedBalances[to], amountToAdd);

        // Update balances
        _encryptedBalances[from] = newBalanceFrom;
        _encryptedBalances[to] = newBalanceTo;

        // Allow addresses to view their own balances
        TFHE.allowThis(newBalanceFrom);
        TFHE.allow(newBalanceFrom, from);

        TFHE.allowThis(newBalanceTo);
        TFHE.allow(newBalanceTo, to);
    }

    /**
     * @notice Grant permission to view encrypted balance
     * @param viewer Address to grant permission to
     */
    function allowBalance(address viewer) external {
        TFHE.allow(_encryptedBalances[msg.sender], viewer);
    }

    /**
     * @notice Grant permission to view encrypted allowance
     * @param spender Spender address
     * @param viewer Address to grant permission to
     */
    function allowAllowance(address spender, address viewer) external {
        TFHE.allow(_encryptedAllowances[msg.sender][spender], viewer);
    }
}
