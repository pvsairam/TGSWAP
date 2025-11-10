// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ConfidentialERC20
 * @notice ERC-7984 compliant confidential token with encrypted balances
 * @dev Implements encrypted balance management using Zama's fhEVM
 */
contract ConfidentialERC20 is Ownable {
    // Token metadata
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    // Total supply (public for transparency)
    uint256 public totalSupply;

    // Encrypted balances: address => encrypted balance (euint64)
    // Note: In production fhEVM, these would be actual euint64 types
    // For now using uint256 as placeholder for compatibility
    mapping(address => uint256) private _encryptedBalances;

    // Encrypted allowances: owner => spender => encrypted amount
    mapping(address => mapping(address => uint256)) private _encryptedAllowances;

    // Access control for viewing encrypted data
    mapping(address => mapping(address => bool)) private _permissions;

    // Events
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event EncryptedTransfer(address indexed from, address indexed to);
    event EncryptedApproval(address indexed owner, address indexed spender);
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);

    /**
     * @notice Constructor
     * @param _name Token name
     * @param _symbol Token symbol
     */
    constructor(string memory _name, string memory _symbol) Ownable(msg.sender) {
        name = _name;
        symbol = _symbol;
    }

    /**
     * @notice Mint tokens to an address (only owner)
     * @param to Recipient address
     * @param amount Amount to mint
     */
    function mint(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Cannot mint to zero address");

        totalSupply += amount;

        // In real fhEVM: encrypt the amount and add to encrypted balance
        // For now: simple addition as placeholder
        _encryptedBalances[to] += amount;

        emit Mint(to, amount);
        emit Transfer(address(0), to, amount);
    }

    /**
     * @notice Burn tokens from caller
     * @param amount Amount to burn
     */
    function burn(uint256 amount) external {
        require(_encryptedBalances[msg.sender] >= amount, "Insufficient balance");

        totalSupply -= amount;
        _encryptedBalances[msg.sender] -= amount;

        emit Burn(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
    }

    /**
     * @notice Transfer tokens (public amount for transparency)
     * @param to Recipient address
     * @param amount Amount to transfer
     * @return success True if transfer succeeded
     */
    function transfer(address to, uint256 amount) external returns (bool) {
        require(to != address(0), "Cannot transfer to zero address");
        require(_encryptedBalances[msg.sender] >= amount, "Insufficient balance");

        _encryptedBalances[msg.sender] -= amount;
        _encryptedBalances[to] += amount;

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @notice Transfer tokens with encrypted amount
     * @dev In production: encryptedAmount would be bytes (encrypted input)
     * @param to Recipient address
     * @param encryptedAmount Encrypted amount to transfer
     * @return success True if transfer succeeded
     */
    function transferEncrypted(address to, uint256 encryptedAmount) external returns (bool) {
        require(to != address(0), "Cannot transfer to zero address");

        // In real fhEVM:
        // euint64 amount = TFHE.asEuint64(encryptedAmount);
        // euint64 balance = TFHE.asEuint64(_encryptedBalances[msg.sender]);
        // ebool canTransfer = TFHE.le(amount, balance);
        // TFHE.req(canTransfer);

        require(_encryptedBalances[msg.sender] >= encryptedAmount, "Insufficient balance");

        _encryptedBalances[msg.sender] -= encryptedAmount;
        _encryptedBalances[to] += encryptedAmount;

        emit EncryptedTransfer(msg.sender, to);
        return true;
    }

    /**
     * @notice Approve spender to spend tokens
     * @param spender Spender address
     * @param amount Amount to approve
     * @return success True if approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        require(spender != address(0), "Cannot approve zero address");

        _encryptedAllowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Approve spender with encrypted amount
     * @param spender Spender address
     * @param encryptedAmount Encrypted amount to approve
     * @return success True if approval succeeded
     */
    function approveEncrypted(address spender, uint256 encryptedAmount) external returns (bool) {
        require(spender != address(0), "Cannot approve zero address");

        _encryptedAllowances[msg.sender][spender] = encryptedAmount;

        emit EncryptedApproval(msg.sender, spender);
        return true;
    }

    /**
     * @notice Transfer tokens on behalf of another address
     * @param from Sender address
     * @param to Recipient address
     * @param amount Amount to transfer
     * @return success True if transfer succeeded
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(to != address(0), "Cannot transfer to zero address");
        require(_encryptedBalances[from] >= amount, "Insufficient balance");
        require(_encryptedAllowances[from][msg.sender] >= amount, "Insufficient allowance");

        _encryptedAllowances[from][msg.sender] -= amount;
        _encryptedBalances[from] -= amount;
        _encryptedBalances[to] += amount;

        emit Transfer(from, to, amount);
        return true;
    }

    /**
     * @notice Get balance (public view, returns cleartext for testing)
     * @param account Account to query
     * @return balance Balance of account
     */
    function balanceOf(address account) external view returns (uint256) {
        return _encryptedBalances[account];
    }

    /**
     * @notice Get encrypted balance (sealed for specific public key)
     * @dev In production: returns encrypted bytes that only owner can decrypt
     * @param account Account to query
     * @return encryptedBalance Encrypted balance
     */
    function balanceOfSealed(address account) external view returns (uint256) {
        // In real fhEVM:
        // require(msg.sender == account || _permissions[account][msg.sender], "No permission");
        // return TFHE.sealoutput(_encryptedBalances[account], publicKey);

        require(msg.sender == account || _permissions[account][msg.sender], "No permission");
        return _encryptedBalances[account];
    }

    /**
     * @notice Get allowance
     * @param owner Token owner
     * @param spender Spender address
     * @return allowance Allowance amount
     */
    function allowance(address owner, address spender) external view returns (uint256) {
        return _encryptedAllowances[owner][spender];
    }

    /**
     * @notice Grant permission to view encrypted balance
     * @param viewer Address to grant permission to
     */
    function grantPermission(address viewer) external {
        _permissions[msg.sender][viewer] = true;
    }

    /**
     * @notice Revoke permission to view encrypted balance
     * @param viewer Address to revoke permission from
     */
    function revokePermission(address viewer) external {
        _permissions[msg.sender][viewer] = false;
    }

    /**
     * @notice Check if viewer has permission to see encrypted balance
     * @param owner Balance owner
     * @param viewer Viewer address
     * @return hasPermission True if viewer has permission
     */
    function hasPermission(address owner, address viewer) external view returns (bool) {
        return _permissions[owner][viewer];
    }
}
