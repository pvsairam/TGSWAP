// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title SwapMath
 * @notice Library for swap calculations
 * @dev Implements constant product formula: x * y = k
 */
library SwapMath {
    /**
     * @notice Calculate output amount given input amount (with 0.3% fee)
     * @dev Formula: amountOut = (amountIn * 997 * reserveOut) / (reserveIn * 1000 + amountIn * 997)
     * @param amountIn Input amount
     * @param reserveIn Input token reserve
     * @param reserveOut Output token reserve
     * @return amountOut Output amount
     */
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "SwapMath: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "SwapMath: INSUFFICIENT_LIQUIDITY");

        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;

        amountOut = numerator / denominator;
    }

    /**
     * @notice Calculate input amount required for exact output amount
     * @dev Formula: amountIn = (reserveIn * amountOut * 1000) / ((reserveOut - amountOut) * 997) + 1
     * @param amountOut Desired output amount
     * @param reserveIn Input token reserve
     * @param reserveOut Output token reserve
     * @return amountIn Required input amount
     */
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "SwapMath: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "SwapMath: INSUFFICIENT_LIQUIDITY");
        require(amountOut < reserveOut, "SwapMath: INSUFFICIENT_RESERVE");

        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;

        amountIn = (numerator / denominator) + 1;
    }

    /**
     * @notice Calculate output amounts for a path of tokens
     * @param amountIn Input amount
     * @param path Array of token addresses
     * @param reserves Array of [reserveIn, reserveOut] for each hop
     * @return amounts Array of output amounts at each step
     */
    function getAmountsOut(
        uint256 amountIn,
        address[] memory path,
        uint256[][] memory reserves
    ) internal pure returns (uint256[] memory amounts) {
        require(path.length >= 2, "SwapMath: INVALID_PATH");
        require(reserves.length == path.length - 1, "SwapMath: INVALID_RESERVES");

        amounts = new uint256[](path.length);
        amounts[0] = amountIn;

        for (uint256 i = 0; i < path.length - 1; i++) {
            amounts[i + 1] = getAmountOut(amounts[i], reserves[i][0], reserves[i][1]);
        }
    }

    /**
     * @notice Calculate input amounts for a path of tokens
     * @param amountOut Desired output amount
     * @param path Array of token addresses
     * @param reserves Array of [reserveIn, reserveOut] for each hop
     * @return amounts Array of input amounts at each step
     */
    function getAmountsIn(
        uint256 amountOut,
        address[] memory path,
        uint256[][] memory reserves
    ) internal pure returns (uint256[] memory amounts) {
        require(path.length >= 2, "SwapMath: INVALID_PATH");
        require(reserves.length == path.length - 1, "SwapMath: INVALID_RESERVES");

        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;

        for (uint256 i = path.length - 1; i > 0; i--) {
            amounts[i - 1] = getAmountIn(amounts[i], reserves[i - 1][0], reserves[i - 1][1]);
        }
    }

    /**
     * @notice Calculate liquidity tokens to mint
     * @param amount0 Amount of token0 being added
     * @param amount1 Amount of token1 being added
     * @param reserve0 Current reserve of token0
     * @param reserve1 Current reserve of token1
     * @param totalSupply Current total supply of LP tokens
     * @return liquidity Amount of LP tokens to mint
     */
    function calculateLiquidity(
        uint256 amount0,
        uint256 amount1,
        uint256 reserve0,
        uint256 reserve1,
        uint256 totalSupply
    ) internal pure returns (uint256 liquidity) {
        if (totalSupply == 0) {
            // Initial liquidity: geometric mean
            liquidity = sqrt(amount0 * amount1);
            require(liquidity > 0, "SwapMath: INSUFFICIENT_LIQUIDITY_MINTED");
        } else {
            // Proportional liquidity
            uint256 liquidity0 = (amount0 * totalSupply) / reserve0;
            uint256 liquidity1 = (amount1 * totalSupply) / reserve1;
            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        }
    }

    /**
     * @notice Calculate square root (Babylonian method)
     * @param y Input value
     * @return z Square root of y
     */
    function sqrt(uint256 y) internal pure returns (uint256 z) {
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

    /**
     * @notice Get minimum of two numbers
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
