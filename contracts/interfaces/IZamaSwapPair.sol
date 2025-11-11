// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IZamaSwapPair
 * @notice Interface for ZamaSwapPair contract
 */
interface IZamaSwapPair {
    // Events
    event Mint(address indexed sender, uint256 liquidity);
    event Burn(address indexed sender, uint256 liquidity, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint256 reserve0, uint256 reserve1);

    // ERC20 functions (since pair is an ERC20 LP token)
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    // Core pair functions
    function token0() external view returns (address);
    function token1() external view returns (address);
    function factory() external view returns (address);

    function getReserves() external view returns (uint256 reserve0, uint256 reserve1, uint32 blockTimestampLast);

    function mint(address to) external returns (uint256 liquidity);
    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;
    function sync() external;

    function initialize(address _token0, address _token1) external;
}
