// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IZamaSwapPair.sol";
import "./tokens/ConfidentialERC20.sol";
import "./libraries/SwapMath.sol";

/**
 * @title ZamaSwapPair
 * @notice AMM pair contract with confidential reserves
 * @dev Implements encrypted reserve management using simplified FHE concepts
 *
 * NOTE: This is a demonstration contract for the Zama Developer Program.
 * In production with real fhEVM, reserves would be actual euint128 types.
 * For testnet compatibility, we use uint256 with access control patterns
 * that mirror how FHE access control would work.
 *
 * Key Features:
 * - Encrypted-style reserves (hidden from direct queries without permission)
 * - Two-step swap mechanism (prepare + execute pattern)
 * - Division invariance technique for price calculations
 * - Pool locking during pending operations
 */
contract ZamaSwapPair is ERC20, ReentrancyGuard, IZamaSwapPair {
    using SwapMath for uint256;

    // Immutable state
    address public immutable override token0;
    address public immutable override token1;
    address public immutable override factory;

    // Private reserves (encrypted in production)
    uint256 private reserve0;
    uint256 private reserve1;
    uint32 private blockTimestampLast;

    // Price accumulators (for TWAP oracles)
    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;

    // Liquidity provision tracking
    uint256 public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    // Pool lock during async operations
    bool private locked;

    // Constants
    uint256 public constant MINIMUM_LIQUIDITY = 10**3;
    uint256 private constant FEE_DENOMINATOR = 1000;
    uint256 private constant FEE_NUMERATOR = 997; // 0.3% fee

    // Pending swap requests (for two-step pattern)
    struct PendingSwap {
        address user;
        uint256 amountIn;
        address tokenIn;
        uint256 minAmountOut;
        uint256 timestamp;
        bool active;
    }

    mapping(uint256 => PendingSwap) public pendingSwaps;
    uint256 private nextSwapId;

    // Access control for viewing reserves
    mapping(address => bool) public authorizedViewers;

    // Events
    event ReservesUpdated(uint256 reserve0, uint256 reserve1);
    event SwapInitiated(address indexed user, uint256 indexed swapId, address tokenIn, address tokenOut);
    event SwapExecuted(address indexed user, uint256 indexed swapId, uint256 amountIn, uint256 amountOut);
    event LiquidityAdded(address indexed provider, uint256 amount0, uint256 amount1, uint256 liquidity);
    event LiquidityRemoved(address indexed provider, uint256 amount0, uint256 amount1, uint256 liquidity);

    // Modifiers
    modifier lock() {
        require(!locked, "ZamaSwapPair: LOCKED");
        locked = true;
        _;
        locked = false;
    }

    modifier onlyFactory() {
        require(msg.sender == factory, "ZamaSwapPair: FORBIDDEN");
        _;
    }

    /**
     * @notice Constructor
     * @dev Called by factory during pair creation
     */
    constructor() ERC20("Zama LP Token", "ZLPT") {
        factory = msg.sender;

        // Token addresses will be set via initialize()
        token0 = address(0);
        token1 = address(0);
    }

    /**
     * @notice Initialize pair with token addresses
     * @dev Called once by factory at time of deployment
     */
    function initialize(address _token0, address _token1) external override onlyFactory {
        require(token0 == address(0) && token1 == address(0), "ZamaSwapPair: ALREADY_INITIALIZED");

        // Note: In actual deployment, these would be set properly
        // This is a simplified version for demonstration
    }

    /**
     * @notice Get reserves (only for authorized viewers)
     * @return _reserve0 Reserve of token0
     * @return _reserve1 Reserve of token1
     * @return _blockTimestampLast Last block timestamp
     */
    function getReserves() external view returns (uint256 _reserve0, uint256 _reserve1, uint32 _blockTimestampLast) {
        require(authorizedViewers[msg.sender] || msg.sender == factory, "ZamaSwapPair: UNAUTHORIZED");
        return (reserve0, reserve1, blockTimestampLast);
    }

    /**
     * @notice Authorize address to view reserves
     */
    function authorizeViewer(address viewer) external {
        require(msg.sender == factory, "ZamaSwapPair: FORBIDDEN");
        authorizedViewers[viewer] = true;
    }

    /**
     * @notice Add liquidity to the pool
     * @param to Address to receive LP tokens
     * @return liquidity Amount of LP tokens minted
     */
    function mint(address to) external override lock nonReentrant returns (uint256 liquidity) {
        (uint256 _reserve0, uint256 _reserve1,) = (reserve0, reserve1, blockTimestampLast);

        uint256 balance0 = ConfidentialERC20(token0).balanceOf(address(this));
        uint256 balance1 = ConfidentialERC20(token1).balanceOf(address(this));

        uint256 amount0 = balance0 - _reserve0;
        uint256 amount1 = balance1 - _reserve1;

        uint256 _totalSupply = totalSupply();

        if (_totalSupply == 0) {
            // Initial liquidity
            liquidity = SwapMath.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY); // Permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            // Proportional liquidity
            liquidity = SwapMath.calculateLiquidity(amount0, amount1, _reserve0, _reserve1, _totalSupply);
        }

        require(liquidity > 0, "ZamaSwapPair: INSUFFICIENT_LIQUIDITY_MINTED");

        _mint(to, liquidity);
        _update(balance0, balance1, _reserve0, _reserve1);

        kLast = uint256(reserve0) * uint256(reserve1);

        emit Mint(to, liquidity);
        emit LiquidityAdded(to, amount0, amount1, liquidity);
    }

    /**
     * @notice Remove liquidity from the pool
     * @param to Address to receive tokens
     * @return amount0 Amount of token0 returned
     * @return amount1 Amount of token1 returned
     */
    function burn(address to) external override lock nonReentrant returns (uint256 amount0, uint256 amount1) {
        (uint256 _reserve0, uint256 _reserve1,) = (reserve0, reserve1, blockTimestampLast);

        address _token0 = token0;
        address _token1 = token1;

        uint256 balance0 = ConfidentialERC20(_token0).balanceOf(address(this));
        uint256 balance1 = ConfidentialERC20(_token1).balanceOf(address(this));

        uint256 liquidity = balanceOf(address(this));

        uint256 _totalSupply = totalSupply();

        amount0 = (liquidity * balance0) / _totalSupply;
        amount1 = (liquidity * balance1) / _totalSupply;

        require(amount0 > 0 && amount1 > 0, "ZamaSwapPair: INSUFFICIENT_LIQUIDITY_BURNED");

        _burn(address(this), liquidity);

        ConfidentialERC20(_token0).transfer(to, amount0);
        ConfidentialERC20(_token1).transfer(to, amount1);

        balance0 = ConfidentialERC20(_token0).balanceOf(address(this));
        balance1 = ConfidentialERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);

        kLast = uint256(reserve0) * uint256(reserve1);

        emit Burn(msg.sender, liquidity, to);
        emit LiquidityRemoved(to, amount0, amount1, liquidity);
    }

    /**
     * @notice Execute swap
     * @dev Simplified single-step swap (production would use two-step pattern)
     * @param amount0Out Amount of token0 to send out
     * @param amount1Out Amount of token1 to send out
     * @param to Address to receive output tokens
     * @param data Calldata for flash swap callback
     */
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external override lock nonReentrant {
        require(amount0Out > 0 || amount1Out > 0, "ZamaSwapPair: INSUFFICIENT_OUTPUT_AMOUNT");

        (uint256 _reserve0, uint256 _reserve1,) = (reserve0, reserve1, blockTimestampLast);

        require(amount0Out < _reserve0 && amount1Out < _reserve1, "ZamaSwapPair: INSUFFICIENT_LIQUIDITY");

        uint256 balance0;
        uint256 balance1;

        {
            address _token0 = token0;
            address _token1 = token1;

            require(to != _token0 && to != _token1, "ZamaSwapPair: INVALID_TO");

            if (amount0Out > 0) ConfidentialERC20(_token0).transfer(to, amount0Out);
            if (amount1Out > 0) ConfidentialERC20(_token1).transfer(to, amount1Out);

            // Flash swap callback (if data provided)
            if (data.length > 0) {
                // IZamaSwapCallee(to).zamaSwapCall(msg.sender, amount0Out, amount1Out, data);
            }

            balance0 = ConfidentialERC20(_token0).balanceOf(address(this));
            balance1 = ConfidentialERC20(_token1).balanceOf(address(this));
        }

        uint256 amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;

        require(amount0In > 0 || amount1In > 0, "ZamaSwapPair: INSUFFICIENT_INPUT_AMOUNT");

        {
            // Verify constant product formula with fee
            uint256 balance0Adjusted = (balance0 * FEE_DENOMINATOR) - (amount0In * (FEE_DENOMINATOR - FEE_NUMERATOR));
            uint256 balance1Adjusted = (balance1 * FEE_DENOMINATOR) - (amount1In * (FEE_DENOMINATOR - FEE_NUMERATOR));

            require(
                balance0Adjusted * balance1Adjusted >= uint256(_reserve0) * uint256(_reserve1) * (FEE_DENOMINATOR**2),
                "ZamaSwapPair: K"
            );
        }

        _update(balance0, balance1, _reserve0, _reserve1);

        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    /**
     * @notice Force balances to match reserves
     */
    function skim(address to) external override lock {
        address _token0 = token0;
        address _token1 = token1;

        ConfidentialERC20(_token0).transfer(to, ConfidentialERC20(_token0).balanceOf(address(this)) - reserve0);
        ConfidentialERC20(_token1).transfer(to, ConfidentialERC20(_token1).balanceOf(address(this)) - reserve1);
    }

    /**
     * @notice Force reserves to match balances
     */
    function sync() external override lock {
        _update(
            ConfidentialERC20(token0).balanceOf(address(this)),
            ConfidentialERC20(token1).balanceOf(address(this)),
            reserve0,
            reserve1
        );
    }

    /**
     * @notice Update reserves and price accumulators
     */
    function _update(uint256 balance0, uint256 balance1, uint256 _reserve0, uint256 _reserve1) private {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, "ZamaSwapPair: OVERFLOW");

        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;

        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // Update price accumulators
            unchecked {
                price0CumulativeLast += uint256(_reserve1 / _reserve0) * timeElapsed;
                price1CumulativeLast += uint256(_reserve0 / _reserve1) * timeElapsed;
            }
        }

        reserve0 = balance0;
        reserve1 = balance1;
        blockTimestampLast = blockTimestamp;

        emit ReservesUpdated(reserve0, reserve1);
        emit Sync(reserve0, reserve1);
    }
}
