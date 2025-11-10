import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { useTelegram } from '../hooks/useTelegram';

// Extend Window interface for ethereum
declare global {
  interface Window {
    ethereum?: any;
  }
}
import {
  getTokenContract,
  getRouterContract,
  getAllTokens,
  formatTokenAmount,
  parseTokenAmount,
  getDeadline,
  calculateMinAmount,
  CONTRACTS,
} from '../utils/contracts';

interface Token {
  symbol: string;
  address: string;
  name: string;
  decimals: number;
}

export const SwapCard: React.FC = () => {
  const { hapticFeedback, showAlert, showConfirm } = useTelegram();

  const [provider, setProvider] = useState<ethers.BrowserProvider | null>(null);
  const [signer, setSigner] = useState<ethers.Signer | null>(null);
  const [account, setAccount] = useState<string>('');

  const availableTokens = getAllTokens();
  const [tokenIn, setTokenIn] = useState<Token | null>(availableTokens[0] || null);
  const [tokenOut, setTokenOut] = useState<Token | null>(availableTokens[1] || null);

  const [amountIn, setAmountIn] = useState('');
  const [amountOut, setAmountOut] = useState('');
  const [estimating, setEstimating] = useState(false);
  const [swapping, setSwapping] = useState(false);

  const [balance, setBalance] = useState('0');
  const [allowance, setAllowance] = useState(0n);

  const [slippage, setSlippage] = useState(0.5); // 0.5%

  // Connect wallet
  useEffect(() => {
    const connectWallet = async () => {
      if (typeof window.ethereum !== 'undefined') {
        try {
          const browserProvider = new ethers.BrowserProvider(window.ethereum);
          setProvider(browserProvider);

          const accounts = await browserProvider.send('eth_requestAccounts', []);
          if (accounts.length > 0) {
            setAccount(accounts[0]);
            const walletSigner = await browserProvider.getSigner();
            setSigner(walletSigner);
          }
        } catch (error) {
          console.error('Failed to connect wallet:', error);
          showAlert('Please connect your wallet to use Zama Swap');
        }
      } else {
        showAlert('Please install MetaMask or another Web3 wallet');
      }
    };

    connectWallet();
  }, [showAlert]);

  // Load balance when tokenIn or account changes
  useEffect(() => {
    if (tokenIn && account && provider) {
      loadBalance();
      loadAllowance();
    }
  }, [tokenIn, account, provider]);

  const loadBalance = async () => {
    if (!provider || !tokenIn || !account) return;

    try {
      const tokenContract = getTokenContract(tokenIn.address, provider);
      const bal = await tokenContract.balanceOf(account);
      setBalance(formatTokenAmount(bal, tokenIn.decimals));
    } catch (error) {
      console.error('Failed to load balance:', error);
      setBalance('0');
    }
  };

  const loadAllowance = async () => {
    if (!provider || !tokenIn || !account) return;

    try {
      const tokenContract = getTokenContract(tokenIn.address, provider);
      const allowanceAmount = await tokenContract.allowance(account, CONTRACTS.router);
      setAllowance(allowanceAmount);
    } catch (error) {
      console.error('Failed to load allowance:', error);
      setAllowance(0n);
    }
  };

  // Estimate output amount
  useEffect(() => {
    if (amountIn && tokenIn && tokenOut && provider && parseFloat(amountIn) > 0) {
      estimateOutput();
    } else {
      setAmountOut('');
    }
  }, [amountIn, tokenIn, tokenOut, provider]);

  const estimateOutput = async () => {
    if (!provider || !tokenIn || !tokenOut || !amountIn) return;

    setEstimating(true);

    try {
      const router = getRouterContract(provider);
      const amountInParsed = parseTokenAmount(amountIn, tokenIn.decimals);

      const estimated = await router.getAmountOut(
        amountInParsed,
        tokenIn.address,
        tokenOut.address
      );

      setAmountOut(formatTokenAmount(estimated, tokenOut.decimals, 6));
    } catch (error) {
      console.error('Failed to estimate output:', error);
      setAmountOut('');
    } finally {
      setEstimating(false);
    }
  };

  const handleSwapTokens = () => {
    // Swap tokenIn and tokenOut
    const temp = tokenIn;
    setTokenIn(tokenOut);
    setTokenOut(temp);
    setAmountIn('');
    setAmountOut('');
    hapticFeedback('light');
  };

  const handleMaxClick = () => {
    if (balance && parseFloat(balance) > 0) {
      setAmountIn(balance);
      hapticFeedback('light');
    }
  };

  const handleApprove = async () => {
    if (!signer || !tokenIn || !amountIn) return;

    hapticFeedback('medium');

    try {
      const tokenContract = getTokenContract(tokenIn.address, signer);
      const amountToApprove = parseTokenAmount(amountIn, tokenIn.decimals);

      showAlert('Approving tokens...');

      const tx = await tokenContract.approve(CONTRACTS.router, amountToApprove);
      await tx.wait();

      showAlert('Approval successful!');
      await loadAllowance();
      hapticFeedback('heavy');
    } catch (error: any) {
      console.error('Approval failed:', error);
      showAlert(`Approval failed: ${error.message || 'Unknown error'}`);
      hapticFeedback('heavy');
    }
  };

  const handleSwap = async () => {
    if (!signer || !tokenIn || !tokenOut || !amountIn || !amountOut) {
      showAlert('Please fill in all fields');
      return;
    }

    const confirmed = await showConfirm(
      `Swap ${amountIn} ${tokenIn.symbol} for ~${amountOut} ${tokenOut.symbol}?`
    );

    if (!confirmed) return;

    setSwapping(true);
    hapticFeedback('medium');

    try {
      const router = getRouterContract(signer);

      const amountInParsed = parseTokenAmount(amountIn, tokenIn.decimals);
      const amountOutParsed = parseTokenAmount(amountOut, tokenOut.decimals);
      const minAmountOut = calculateMinAmount(amountOutParsed, slippage);

      const path = [tokenIn.address, tokenOut.address];
      const deadline = getDeadline(20);

      showAlert('Swapping tokens...');

      const tx = await router.swapExactTokensForTokens(
        amountInParsed,
        minAmountOut,
        path,
        account,
        deadline
      );

      showAlert('Transaction submitted. Waiting for confirmation...');

      const receipt = await tx.wait();

      if (receipt && receipt.status === 1) {
        showAlert('Swap completed successfully!');
        hapticFeedback('heavy');

        // Reset form
        setAmountIn('');
        setAmountOut('');

        // Reload balance
        await loadBalance();
      } else {
        showAlert('Transaction failed');
        hapticFeedback('heavy');
      }
    } catch (error: any) {
      console.error('Swap failed:', error);
      showAlert(`Swap failed: ${error.message || 'Unknown error'}`);
      hapticFeedback('heavy');
    } finally {
      setSwapping(false);
    }
  };

  const needsApproval = () => {
    if (!amountIn || !tokenIn) return false;
    const amountInParsed = parseTokenAmount(amountIn, tokenIn.decimals);
    return allowance < amountInParsed;
  };

  return (
    <div className="swap-card bg-white dark:bg-gray-800 rounded-2xl shadow-lg p-6 max-w-md mx-auto">
      <h2 className="text-2xl font-bold mb-6 text-center text-telegram-text">Swap Tokens</h2>

      {/* From Token */}
      <div className="mb-4">
        <label className="block text-sm font-medium mb-2 text-telegram-hint">From</label>
        <div className="bg-gray-100 dark:bg-gray-700 rounded-xl p-4">
          <div className="flex justify-between items-center mb-2">
            <input
              type="number"
              value={amountIn}
              onChange={(e) => setAmountIn(e.target.value)}
              placeholder="0.0"
              className="text-2xl font-bold bg-transparent border-none outline-none w-full"
              disabled={swapping}
            />
            <button
              onClick={handleMaxClick}
              className="text-sm text-telegram-link font-medium px-2 py-1 rounded"
            >
              MAX
            </button>
          </div>
          <div className="flex justify-between items-center">
            <select
              value={tokenIn?.symbol || ''}
              onChange={(e) => {
                const token = availableTokens.find((t) => t.symbol === e.target.value);
                if (token) setTokenIn(token);
              }}
              className="text-lg font-medium bg-transparent border-none outline-none"
              disabled={swapping}
            >
              {availableTokens.map((token) => (
                <option key={token.symbol} value={token.symbol}>
                  {token.symbol}
                </option>
              ))}
            </select>
            <div className="text-sm text-telegram-hint">
              Balance: {balance}
            </div>
          </div>
        </div>
      </div>

      {/* Swap Button */}
      <div className="flex justify-center my-4">
        <button
          onClick={handleSwapTokens}
          className="bg-telegram-button text-telegram-buttonText rounded-full p-3 hover:opacity-80 transition"
          disabled={swapping}
        >
          <svg
            className="w-6 h-6"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M7 16V4m0 0L3 8m4-4l4 4m6 0v12m0 0l4-4m-4 4l-4-4"
            />
          </svg>
        </button>
      </div>

      {/* To Token */}
      <div className="mb-6">
        <label className="block text-sm font-medium mb-2 text-telegram-hint">To</label>
        <div className="bg-gray-100 dark:bg-gray-700 rounded-xl p-4">
          <div className="flex justify-between items-center mb-2">
            <input
              type="text"
              value={estimating ? 'Calculating...' : amountOut}
              readOnly
              placeholder="0.0"
              className="text-2xl font-bold bg-transparent border-none outline-none w-full"
            />
          </div>
          <div className="flex justify-between items-center">
            <select
              value={tokenOut?.symbol || ''}
              onChange={(e) => {
                const token = availableTokens.find((t) => t.symbol === e.target.value);
                if (token) setTokenOut(token);
              }}
              className="text-lg font-medium bg-transparent border-none outline-none"
              disabled={swapping}
            >
              {availableTokens.map((token) => (
                <option key={token.symbol} value={token.symbol}>
                  {token.symbol}
                </option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {/* Slippage Settings */}
      <div className="mb-4 p-3 bg-gray-100 dark:bg-gray-700 rounded-lg">
        <div className="flex justify-between items-center text-sm">
          <span className="text-telegram-hint">Slippage Tolerance</span>
          <div className="flex gap-2">
            {[0.1, 0.5, 1.0].map((value) => (
              <button
                key={value}
                onClick={() => setSlippage(value)}
                className={`px-3 py-1 rounded ${
                  slippage === value
                    ? 'bg-telegram-button text-telegram-buttonText'
                    : 'bg-gray-200 dark:bg-gray-600'
                }`}
              >
                {value}%
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Action Button */}
      {!account ? (
        <button
          onClick={() => window.location.reload()}
          className="w-full bg-telegram-button text-telegram-buttonText py-4 rounded-xl font-bold text-lg"
        >
          Connect Wallet
        </button>
      ) : needsApproval() ? (
        <button
          onClick={handleApprove}
          disabled={swapping || !amountIn}
          className="w-full bg-yellow-500 text-white py-4 rounded-xl font-bold text-lg disabled:opacity-50 disabled:cursor-not-allowed"
        >
          Approve {tokenIn?.symbol}
        </button>
      ) : (
        <button
          onClick={handleSwap}
          disabled={swapping || !amountIn || !amountOut || estimating}
          className="w-full bg-telegram-button text-telegram-buttonText py-4 rounded-xl font-bold text-lg disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {swapping ? 'Swapping...' : 'Swap'}
        </button>
      )}

      {/* Privacy Badge */}
      <div className="mt-4 text-center text-sm text-telegram-hint">
        🔒 Your swap amounts are kept confidential with FHE
      </div>
    </div>
  );
};
