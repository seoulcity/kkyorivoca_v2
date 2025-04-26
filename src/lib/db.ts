// src/lib/db.ts
import { Pool } from 'pg';

// Handle both Vite's import.meta.env and Node's process.env
const getEnv = (key: string): string => {
  if (typeof process !== 'undefined' && process.env && process.env[key]) {
    return process.env[key] as string;
  }
  // @ts-ignore - Vite specific
  if (typeof import.meta !== 'undefined' && import.meta.env && import.meta.env[key]) {
    // @ts-ignore - Vite specific
    return import.meta.env[key] as string;
  }
  throw new Error(`Environment variable ${key} not found`);
};

// Initialize connection pool using environment variables
const pool = new Pool({
  host: getEnv('PG_HOST'),
  port: parseInt(getEnv('PG_PORT'), 10),
  database: getEnv('PG_DATABASE'),
  user: getEnv('PG_USER'),
  password: getEnv('PG_PASSWORD'),
  ssl: true
});

// Log connection events
pool.on('connect', () => {
  console.log('Connected to PostgreSQL database');
});

pool.on('error', (err: Error) => {
  console.error('Unexpected error on idle client', err);
});

/**
 * Execute a query on the database
 * @param text - SQL query text
 * @param params - Query parameters
 * @returns Query result
 */
export const query = async (text: string, params?: any[]) => {
  const client = await pool.connect();
  try {
    const result = await client.query(text, params);
    return result;
  } finally {
    client.release();
  }
};

/**
 * Get a client from the pool
 * For transactions or multiple queries in sequence
 */
export const getClient = async () => {
  const client = await pool.connect();
  return client;
};

export default {
  query,
  getClient,
  pool
}; 