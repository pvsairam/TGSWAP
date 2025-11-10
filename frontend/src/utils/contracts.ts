import { ethers } from 'ethers';
import contractsConfig from '../contracts.json';

// Minimal ABIs for the contracts
export const ERC20_ABI = [
  'function name() view returns (string)',
  'function symbol() view returns (string)',
  'function decimals() view returns (uint8)',
  'function totalSupply() view returns (uint256)',
  'function balanceOf(address) view returns (uint256)',
  'function transfer(address to, uint256 amount) returns (bool)',
  'function approve(address spender, uint256 amount) returns (bool)',
  'function allowance(address owner, address spender) view returns (uint256)',
  'function transferFrom(address from, address to, uint256 amount) returns (bool)',
];

export const ROUTER_ABI = [
  'function factory() view returns (address)',
  'function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] path, address to, uint256 deadline) returns (uint256[])',
  'function swapTokensForExactTokens(uint256 amountOut, uint256 amountInMax, address[] path, address to, uint256 deadline) returns (uint256[])',
  'function addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) returns (uint256 amountA, uint256 amountB, uint256 liquidity)',
  'function removeLiquidity(address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) returns (uint256 amountA, uint256 amountB)',
  'function getAmountOut(uint256 amountIn, address tokenIn, address tokenOut) view returns (uint256 amountOut)',
  'function getAmountsOut(uint256 amountIn, address[] path) view returns (uint256[])',
];

export const PAIR_ABI = [
  'function token0() view returns (address)',
  'function token1() view returns (address)',
  'function getReserves() view returns (uint256 reserve0, uint256 reserve1, uint32 blockTimestampLast)',
  'function totalSupply() view returns (uint256)',
  'function balanceOf(address) view returns (uint256)',
  'function approve(address spender, uint256 amount) returns (bool)',
];

export const FACTORY_ABI = [
  'function getPair(address tokenA, address tokenB) view returns (address pair)',
  'function allPairs(uint256) view returns (address pair)',
  'function allPairsLength() view returns (uint256)',
  'function createPair(address tokenA, address tokenB) returns (address pair)',
];

// Contract addresses from deployed config
export const CONTRACTS = contractsConfig.contracts;
export const CHAIN_ID = contractsConfig.chainId;

// Helper functions to get contract instances
export function getTokenContract(
  tokenAddress: string,
  signerOrProvider: ethers.Signer | ethers.Provider
): ethers.Contract {
  return new ethers.Contract(tokenAddress, ERC20_ABI, signerOrProvider);
}

export function getRouterContract(
  signerOrProvider: ethers.Signer | ethers.Provider
): ethers.Contract {
  return new ethers.Contract(CONTRACTS.router, ROUTER_ABI, signerOrProvider);
}

export function getPairContract(
  pairAddress: string,
  signerOrProvider: ethers.Signer | ethers.Provider
): ethers.Contract {
  return new ethers.Contract(pairAddress, PAIR_ABI, signerOrProvider);
}

export function getFactoryContract(
  signerOrProvider: ethers.Signer | ethers.Provider
): ethers.Contract {
  return new ethers.Contract(CONTRACTS.factory, FACTORY_ABI, signerOrProvider);
}

// Utility to format token amount
export function formatTokenAmount(amount: bigint, decimals: number = 18, displayDecimals: number = 4): string {
  const formatted = ethers.formatUnits(amount, decimals);
  const num = parseFloat(formatted);

  if (num === 0) return '0';
  if (num < 0.0001) return '< 0.0001';

  return num.toFixed(displayDecimals);
}

// Utility to parse token amount
export function parseTokenAmount(amount: string, decimals: number = 18): bigint {
  try {
    return ethers.parseUnits(amount, decimals);
  } catch (error) {
    console.error('Error parsing token amount:', error);
    return 0n;
  }
}

// Calculate deadline (20 minutes from now)
export function getDeadline(minutesFromNow: number = 20): number {
  return Math.floor(Date.now() / 1000) + (minutesFromNow * 60);
}

// Calculate minimum amount with slippage tolerance
export function calculateMinAmount(amount: bigint, slippageTolerance: number = 0.5): bigint {
  // slippageTolerance is in percentage (e.g., 0.5 for 0.5%)
  const slippageBps = BigInt(Math.floor(slippageTolerance * 100));
  return (amount * (10000n - slippageBps)) / 10000n;
}

// Get token info from config
export function getTokenInfo(symbolOrAddress: string) {
  // Check if it's an address
  if (symbolOrAddress.startsWith('0x')) {
    for (const [, token] of Object.entries(CONTRACTS.tokens)) {
      if (token.address.toLowerCase() === symbolOrAddress.toLowerCase()) {
        return token;
      }
    }
    return null;
  }

  // Otherwise treat as symbol
  const token = CONTRACTS.tokens[symbolOrAddress as keyof typeof CONTRACTS.tokens];
  return token || null;
}

// Get all available tokens
export function getAllTokens() {
  return Object.values(CONTRACTS.tokens);
}

// Check if transaction was successful
export async function waitForTransaction(
  provider: ethers.Provider,
  txHash: string,
  confirmations: number = 1
): Promise<ethers.TransactionReceipt | null> {
  try {
    const receipt = await provider.waitForTransaction(txHash, confirmations);
    return receipt;
  } catch (error) {
    console.error('Error waiting for transaction:', error);
    return null;
  }
}

// Format address for display (0x1234...5678)
export function formatAddress(address: string, chars: number = 4): string {
  if (!address) return '';
  return `${address.substring(0, chars + 2)}...${address.substring(address.length - chars)}`;
}

// Check if address is valid
export function isValidAddress(address: string): boolean {
  return ethers.isAddress(address);
}
