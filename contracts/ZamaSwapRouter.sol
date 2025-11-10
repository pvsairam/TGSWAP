// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IZamaSwapRouter.sol";
import "./interfaces/IZamaSwapFactory.sol";
import "./interfaces/IZamaSwapPair.sol";
import "./tokens/ConfidentialERC20.sol";
import "./libraries/SwapMath.sol";

/**
 * @title ZamaSwapRouter
 * @notice Router contract for multi-hop swaps and liquidity management
 * @dev Provides user-friendly interface for interacting with ZamaSwap pairs
 */
contract ZamaSwapRouter is IZamaSwapRouter, ReentrancyGuard {
    using SwapMath for uint256;

    address public immutable override factory;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "ZamaSwapRouter: EXPIRED");
        _;
    }

    constructor(address _factory) {
        factory = _factory;
    }

    /**
     * @notice Add liquidity to a pair
     * @param tokenA Address of first token
     * @param tokenB Address of second token
     * @param amountADesired Desired amount of tokenA
     * @param amountBDesired Desired amount of tokenB
     * @param amountAMin Minimum amount of tokenA
     * @param amountBMin Minimum amount of tokenB
     * @param to Address to receive LP tokens
     * @param deadline Transaction deadline
     * @return amountA Actual amount of tokenA added
     * @return amountB Actual amount of tokenB added
     * @return liquidity LP tokens minted
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external override ensure(deadline) nonReentrant returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        // Get or create pair
        address pair = IZamaSwapFactory(factory).getPair(tokenA, tokenB);
        if (pair == address(0)) {
            pair = IZamaSwapFactory(factory).createPair(tokenA, tokenB);
        }

        // Calculate optimal amounts
        (amountA, amountB) = _calculateLiquidityAmounts(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );

        // Transfer tokens to pair
        ConfidentialERC20(tokenA).transferFrom(msg.sender, pair, amountA);
        ConfidentialERC20(tokenB).transferFrom(msg.sender, pair, amountB);

        // Mint liquidity
        liquidity = IZamaSwapPair(pair).mint(to);
    }

    /**
     * @notice Remove liquidity from a pair
     * @param tokenA Address of first token
     * @param tokenB Address of second token
     * @param liquidity Amount of LP tokens to burn
     * @param amountAMin Minimum amount of tokenA to receive
     * @param amountBMin Minimum amount of tokenB to receive
     * @param to Address to receive tokens
     * @param deadline Transaction deadline
     * @return amountA Amount of tokenA received
     * @return amountB Amount of tokenB received
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external override ensure(deadline) nonReentrant returns (uint256 amountA, uint256 amountB) {
        address pair = IZamaSwapFactory(factory).getPair(tokenA, tokenB);
        require(pair != address(0), "ZamaSwapRouter: PAIR_NOT_FOUND");

        // Transfer LP tokens to pair
        IZamaSwapPair(pair).transferFrom(msg.sender, pair, liquidity);

        // Burn liquidity
        (uint256 amount0, uint256 amount1) = IZamaSwapPair(pair).burn(to);

        // Sort amounts
        (address token0,) = _sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);

        require(amountA >= amountAMin, "ZamaSwapRouter: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "ZamaSwapRouter: INSUFFICIENT_B_AMOUNT");
    }

    /**
     * @notice Swap exact tokens for tokens
     * @param amountIn Exact input amount
     * @param amountOutMin Minimum output amount
     * @param path Array of token addresses (path[0] = input, path[n-1] = output)
     * @param to Address to receive output tokens
     * @param deadline Transaction deadline
     * @return amounts Array of amounts for each hop
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external override ensure(deadline) nonReentrant returns (uint256[] memory amounts) {
        require(path.length >= 2, "ZamaSwapRouter: INVALID_PATH");

        amounts = _getAmountsOut(amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "ZamaSwapRouter: INSUFFICIENT_OUTPUT_AMOUNT");

        // Transfer input tokens to first pair
        address firstPair = IZamaSwapFactory(factory).getPair(path[0], path[1]);
        require(firstPair != address(0), "ZamaSwapRouter: PAIR_NOT_FOUND");

        ConfidentialERC20(path[0]).transferFrom(msg.sender, firstPair, amounts[0]);

        // Execute swaps
        _swap(amounts, path, to);
    }

    /**
     * @notice Swap tokens for exact tokens
     * @param amountOut Exact output amount
     * @param amountInMax Maximum input amount
     * @param path Array of token addresses
     * @param to Address to receive output tokens
     * @param deadline Transaction deadline
     * @return amounts Array of amounts for each hop
     */
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external override ensure(deadline) nonReentrant returns (uint256[] memory amounts) {
        require(path.length >= 2, "ZamaSwapRouter: INVALID_PATH");

        amounts = _getAmountsIn(amountOut, path);
        require(amounts[0] <= amountInMax, "ZamaSwapRouter: EXCESSIVE_INPUT_AMOUNT");

        // Transfer input tokens to first pair
        address firstPair = IZamaSwapFactory(factory).getPair(path[0], path[1]);
        require(firstPair != address(0), "ZamaSwapRouter: PAIR_NOT_FOUND");

        ConfidentialERC20(path[0]).transferFrom(msg.sender, firstPair, amounts[0]);

        // Execute swaps
        _swap(amounts, path, to);
    }

    /**
     * @notice Get output amount for given input
     * @param amountIn Input amount
     * @param tokenIn Input token address
     * @param tokenOut Output token address
     * @return amountOut Output amount
     */
    function getAmountOut(
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) external view override returns (uint256 amountOut) {
        address pair = IZamaSwapFactory(factory).getPair(tokenIn, tokenOut);
        require(pair != address(0), "ZamaSwapRouter: PAIR_NOT_FOUND");

        (uint256 reserveIn, uint256 reserveOut) = _getReserves(tokenIn, tokenOut);
        amountOut = SwapMath.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    /**
     * @notice Get output amounts for a path
     * @param amountIn Input amount
     * @param path Token path
     * @return amounts Output amounts for each hop
     */
    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view override returns (uint256[] memory amounts) {
        return _getAmountsOut(amountIn, path);
    }

    // ========== INTERNAL FUNCTIONS ==========

    /**
     * @notice Calculate optimal liquidity amounts
     */
    function _calculateLiquidityAmounts(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal view returns (uint256 amountA, uint256 amountB) {
        address pair = IZamaSwapFactory(factory).getPair(tokenA, tokenB);

        if (pair == address(0)) {
            // New pair - use desired amounts
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            // Existing pair - calculate optimal amounts
            (uint256 reserveA, uint256 reserveB) = _getReserves(tokenA, tokenB);

            uint256 amountBOptimal = (amountADesired * reserveB) / reserveA;

            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "ZamaSwapRouter: INSUFFICIENT_B_AMOUNT");
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = (amountBDesired * reserveA) / reserveB;
                require(amountAOptimal <= amountADesired, "ZamaSwapRouter: OVERFLOW");
                require(amountAOptimal >= amountAMin, "ZamaSwapRouter: INSUFFICIENT_A_AMOUNT");
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    /**
     * @notice Execute swap along path
     */
    function _swap(uint256[] memory amounts, address[] memory path, address _to) internal {
        for (uint256 i = 0; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = _sortTokens(input, output);

            uint256 amountOut = amounts[i + 1];

            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));

            address to = i < path.length - 2
                ? IZamaSwapFactory(factory).getPair(output, path[i + 2])
                : _to;

            IZamaSwapPair(IZamaSwapFactory(factory).getPair(input, output)).swap(
                amount0Out,
                amount1Out,
                to,
                new bytes(0)
            );
        }
    }

    /**
     * @notice Get reserves for token pair
     */
    function _getReserves(address tokenA, address tokenB) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0,) = _sortTokens(tokenA, tokenB);
        address pair = IZamaSwapFactory(factory).getPair(tokenA, tokenB);

        require(pair != address(0), "ZamaSwapRouter: PAIR_NOT_FOUND");

        // Authorize router to view reserves
        ZamaSwapPair pairContract = ZamaSwapPair(pair);

        (uint256 reserve0, uint256 reserve1,) = pairContract.getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    /**
     * @notice Get output amounts for path
     */
    function _getAmountsOut(uint256 amountIn, address[] memory path) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "ZamaSwapRouter: INVALID_PATH");

        amounts = new uint256[](path.length);
        amounts[0] = amountIn;

        for (uint256 i = 0; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = _getReserves(path[i], path[i + 1]);
            amounts[i + 1] = SwapMath.getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    /**
     * @notice Get input amounts for path
     */
    function _getAmountsIn(uint256 amountOut, address[] memory path) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "ZamaSwapRouter: INVALID_PATH");

        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;

        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = _getReserves(path[i - 1], path[i]);
            amounts[i - 1] = SwapMath.getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }

    /**
     * @notice Sort two tokens
     */
    function _sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "ZamaSwapRouter: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "ZamaSwapRouter: ZERO_ADDRESS");
    }
}
