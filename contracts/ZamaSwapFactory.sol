// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./ZamaSwapPair.sol";
import "./interfaces/IZamaSwapFactory.sol";

/**
 * @title ZamaSwapFactory
 * @notice Factory contract for creating ZamaSwapPair instances
 * @dev Manages pair creation and protocol fee configuration
 */
contract ZamaSwapFactory is IZamaSwapFactory {
    address public override feeTo;
    address public override feeToSetter;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    /**
     * @notice Get total number of pairs created
     * @return Number of pairs
     */
    function allPairsLength() external view override returns (uint256) {
        return allPairs.length;
    }

    /**
     * @notice Create a new trading pair
     * @param tokenA First token address
     * @param tokenB Second token address
     * @return pair Address of created pair
     */
    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, "ZamaSwapFactory: IDENTICAL_ADDRESSES");

        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        require(token0 != address(0), "ZamaSwapFactory: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "ZamaSwapFactory: PAIR_EXISTS");

        // Create new pair contract
        bytes memory bytecode = type(ZamaSwapPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));

        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        // Initialize the pair
        IZamaSwapPair(pair).initialize(token0, token1);

        // Store pair info
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        allPairs.push(pair);

        // Authorize router and factory to view reserves
        ZamaSwapPair(pair).authorizeViewer(address(this));

        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    /**
     * @notice Set fee recipient address
     * @param _feeTo New fee recipient
     */
    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, "ZamaSwapFactory: FORBIDDEN");
        feeTo = _feeTo;
    }

    /**
     * @notice Set fee setter address
     * @param _feeToSetter New fee setter
     */
    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, "ZamaSwapFactory: FORBIDDEN");
        feeToSetter = _feeToSetter;
    }

    /**
     * @notice Get pair address for two tokens (order-agnostic)
     * @param tokenA First token
     * @param tokenB Second token
     * @return pair Pair address (or zero if doesn't exist)
     */
    function getPairAddress(address tokenA, address tokenB) external view returns (address pair) {
        return getPair[tokenA][tokenB];
    }
}
