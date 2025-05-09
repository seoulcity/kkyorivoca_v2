// src/lib/config.ts
// This file provides a central access point for environment variables

// Handle both Vite's import.meta.env and Node's process.env
export const getEnv = (key: string, defaultValue?: string): string => {
  if (typeof process !== 'undefined' && process.env && process.env[key]) {
    return process.env[key] as string;
  }
  // @ts-ignore - Vite specific
  if (typeof import.meta !== 'undefined' && import.meta.env && import.meta.env[key]) {
    // @ts-ignore - Vite specific
    return import.meta.env[key] as string;
  }
  if (defaultValue !== undefined) {
    return defaultValue;
  }
  throw new Error(`Environment variable ${key} not found`);
};

// Service configuration
export const SERVICE_TITLE = getEnv('VITE_SERVICE_TITLE', 'GenPub');
export const SERVICE_EMAIL = getEnv('VITE_SERVICE_EMAIL', 'contact@genpub.com');

// Site configuration
export const SITE_URL = getEnv('VITE_SITE_URL', 'https://genpub.vercel.app'); 