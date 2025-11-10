import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import './index.css';

// Polyfills for Telegram WebApp
if (typeof window !== 'undefined') {
  // Ensure global is defined for some libraries
  (window as any).global = window;

  // Log initialization
  console.log('Zama Swap initializing...');
  console.log('Telegram WebApp available:', !!window.Telegram?.WebApp);

  // Check if running inside Telegram
  const isTelegram = window.Telegram?.WebApp?.initData !== '';
  console.log('Running in Telegram:', isTelegram);
}

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
