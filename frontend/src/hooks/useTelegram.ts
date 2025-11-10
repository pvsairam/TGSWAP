import { useEffect, useState, useCallback } from 'react';
import { TelegramWebApp } from '../types';

export const useTelegram = () => {
  const [tg, setTg] = useState<TelegramWebApp | null>(null);
  const [user, setUser] = useState<any>(null);
  const [startParam, setStartParam] = useState<string | undefined>(undefined);
  const [isReady, setIsReady] = useState(false);

  useEffect(() => {
    if (typeof window !== 'undefined' && window.Telegram?.WebApp) {
      const webapp = window.Telegram.WebApp;

      // Initialize Telegram WebApp
      webapp.ready();
      webapp.expand();

      setTg(webapp);
      setUser(webapp.initDataUnsafe.user);
      setStartParam(webapp.initDataUnsafe.start_param);

      // Set theme colors
      if (webapp.backgroundColor) {
        document.body.style.backgroundColor = webapp.backgroundColor;
      }

      // Apply theme colors to CSS variables
      if (webapp.themeParams) {
        const root = document.documentElement;
        Object.entries(webapp.themeParams).forEach(([key, value]) => {
          root.style.setProperty(`--tg-theme-${key.replace(/_/g, '-')}`, value);
        });
      }

      setIsReady(true);

      console.log('Telegram WebApp initialized:', {
        user: webapp.initDataUnsafe.user,
        colorScheme: webapp.colorScheme,
      });
    } else {
      console.warn('Telegram WebApp not available. Running in browser mode.');
      setIsReady(true);
    }
  }, []);

  const showMainButton = useCallback((text: string, onClick: () => void) => {
    if (tg?.MainButton) {
      tg.MainButton.setText(text);
      tg.MainButton.show();
      tg.MainButton.enable();
      tg.MainButton.onClick(onClick);
    }
  }, [tg]);

  const hideMainButton = useCallback(() => {
    if (tg?.MainButton) {
      tg.MainButton.hide();
    }
  }, [tg]);

  const showProgress = useCallback(() => {
    if (tg?.MainButton) {
      tg.MainButton.showProgress(false);
    }
  }, [tg]);

  const hideProgress = useCallback(() => {
    if (tg?.MainButton) {
      tg.MainButton.hideProgress();
    }
  }, [tg]);

  const hapticFeedback = useCallback((style: 'light' | 'medium' | 'heavy' = 'medium') => {
    if (tg?.HapticFeedback) {
      tg.HapticFeedback.impactOccurred(style);
    }
  }, [tg]);

  const notificationFeedback = useCallback((type: 'error' | 'success' | 'warning') => {
    if (tg?.HapticFeedback) {
      tg.HapticFeedback.notificationOccurred(type);
    }
  }, [tg]);

  const showAlert = useCallback((message: string, callback?: () => void) => {
    if (tg?.showAlert) {
      tg.showAlert(message, callback);
    } else {
      alert(message);
      callback?.();
    }
  }, [tg]);

  const showConfirm = useCallback((message: string): Promise<boolean> => {
    return new Promise((resolve) => {
      if (tg?.showConfirm) {
        tg.showConfirm(message, (confirmed) => {
          resolve(confirmed);
        });
      } else {
        resolve(confirm(message));
      }
    });
  }, [tg]);

  const close = useCallback(() => {
    tg?.close();
  }, [tg]);

  const openLink = useCallback((url: string) => {
    if (tg?.openLink) {
      tg.openLink(url);
    } else {
      window.open(url, '_blank');
    }
  }, [tg]);

  const sendData = useCallback((data: any) => {
    if (tg?.sendData) {
      tg.sendData(JSON.stringify(data));
    }
  }, [tg]);

  return {
    tg,
    user,
    startParam,
    isReady,
    showMainButton,
    hideMainButton,
    showProgress,
    hideProgress,
    hapticFeedback,
    notificationFeedback,
    showAlert,
    showConfirm,
    close,
    openLink,
    sendData,
    colorScheme: tg?.colorScheme || 'light',
    themeParams: tg?.themeParams || {},
  };
};
