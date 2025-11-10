import React, { useEffect } from 'react';
import { SwapCard } from './components/SwapCard';
import { useTelegram } from './hooks/useTelegram';

function App() {
  const { tg, user, isReady, colorScheme } = useTelegram();

  useEffect(() => {
    // Apply Telegram theme
    if (colorScheme === 'dark') {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  }, [colorScheme]);

  if (!isReady) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center">
          <div className="loader mb-4"></div>
          <p className="text-telegram-hint">Loading Zama Swap...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-telegram-bg p-4">
      {/* Header */}
      <header className="max-w-md mx-auto mb-6">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 bg-gradient-to-br from-purple-500 to-blue-500 rounded-full flex items-center justify-center">
              <span className="text-2xl">🔒</span>
            </div>
            <div>
              <h1 className="text-2xl font-bold text-telegram-text">Zama Swap</h1>
              <p className="text-sm text-telegram-hint">Confidential DEX</p>
            </div>
          </div>
          {user && (
            <div className="text-right">
              <p className="text-sm font-medium text-telegram-text">{user.first_name}</p>
              <p className="text-xs text-telegram-hint">@{user.username || 'user'}</p>
            </div>
          )}
        </div>

        {/* Info Banner */}
        <div className="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-3 mb-4">
          <div className="flex items-start gap-2">
            <span className="text-blue-500 text-lg">ℹ️</span>
            <div className="text-sm text-blue-800 dark:text-blue-200">
              <p className="font-medium mb-1">Privacy-First Trading</p>
              <p className="text-xs">
                All swap amounts are encrypted using Zama's FHE technology. Your trading activity stays private.
              </p>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-md mx-auto">
        <SwapCard />

        {/* Features */}
        <div className="mt-8 grid grid-cols-3 gap-4 text-center">
          <div className="p-4 bg-white dark:bg-gray-800 rounded-xl shadow">
            <div className="text-2xl mb-2">🔐</div>
            <div className="text-xs font-medium text-telegram-text">Encrypted</div>
            <div className="text-xs text-telegram-hint">Balances</div>
          </div>
          <div className="p-4 bg-white dark:bg-gray-800 rounded-xl shadow">
            <div className="text-2xl mb-2">🛡️</div>
            <div className="text-xs font-medium text-telegram-text">No MEV</div>
            <div className="text-xs text-telegram-hint">Protection</div>
          </div>
          <div className="p-4 bg-white dark:bg-gray-800 rounded-xl shadow">
            <div className="text-2xl mb-2">⚡</div>
            <div className="text-xs font-medium text-telegram-text">Fast</div>
            <div className="text-xs text-telegram-hint">Swaps</div>
          </div>
        </div>

        {/* About Section */}
        <div className="mt-8 bg-white dark:bg-gray-800 rounded-xl shadow p-6">
          <h3 className="text-lg font-bold mb-3 text-telegram-text">About Zama Swap</h3>
          <div className="space-y-3 text-sm text-telegram-hint">
            <p>
              Zama Swap is a confidential DEX built on Zama's fhEVM technology, enabling fully
              private token swaps on-chain.
            </p>
            <div className="flex flex-wrap gap-2">
              <span className="px-3 py-1 bg-purple-100 dark:bg-purple-900/30 text-purple-800 dark:text-purple-200 rounded-full text-xs font-medium">
                FHE Encryption
              </span>
              <span className="px-3 py-1 bg-blue-100 dark:bg-blue-900/30 text-blue-800 dark:text-blue-200 rounded-full text-xs font-medium">
                Sepolia Testnet
              </span>
              <span className="px-3 py-1 bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-200 rounded-full text-xs font-medium">
                Telegram Mini App
              </span>
            </div>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="max-w-md mx-auto mt-8 pb-8 text-center">
        <p className="text-xs text-telegram-hint mb-2">
          Powered by Zama fhEVM | Built for Zama Developer Program 2025
        </p>
        <div className="flex justify-center gap-4 text-xs">
          <a
            href="https://github.com/pvsairam/TGSWAP"
            target="_blank"
            rel="noopener noreferrer"
            className="text-telegram-link hover:underline"
          >
            GitHub
          </a>
          <a
            href="https://docs.zama.ai"
            target="_blank"
            rel="noopener noreferrer"
            className="text-telegram-link hover:underline"
          >
            Docs
          </a>
        </div>
      </footer>
    </div>
  );
}

export default App;
