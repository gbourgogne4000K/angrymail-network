/**
 * Database connection and query wrapper
 * Uses mysql2/promise for async/await support
 */

const mysql = require('mysql2/promise');
require('dotenv').config();

// Connection pool configuration
const poolConfig = {
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT) || 3306,
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  enableKeepAlive: true,
  keepAliveInitialDelay: 0,
  charset: 'utf8mb4'
};

// Create connection pool
let pool;

/**
 * Initialize database pool
 */
function initPool() {
  if (!pool) {
    pool = mysql.createPool(poolConfig);
    console.log('✓ Database pool created');
  }
  return pool;
}

/**
 * Get database connection from pool
 */
async function getConnection() {
  if (!pool) {
    initPool();
  }
  return await pool.getConnection();
}

/**
 * Execute a query with parameters
 * @param {string} sql - SQL query
 * @param {Array} params - Query parameters
 * @returns {Promise<Array>} Query results
 */
async function query(sql, params = []) {
  const connection = await getConnection();
  try {
    const [rows] = await connection.execute(sql, params);
    return rows;
  } finally {
    connection.release();
  }
}

/**
 * Execute a query and return first row only
 */
async function queryOne(sql, params = []) {
  const rows = await query(sql, params);
  return rows[0] || null;
}

/**
 * Test database connection
 */
async function testConnection() {
  try {
    const connection = await getConnection();
    await connection.ping();
    connection.release();
    return true;
  } catch (error) {
    console.error('Database connection failed:', error.message);
    return false;
  }
}

/**
 * Close pool (for graceful shutdown)
 */
async function closePool() {
  if (pool) {
    await pool.end();
    console.log('✓ Database pool closed');
  }
}

/**
 * Transaction helper
 */
async function transaction(callback) {
  const connection = await getConnection();
  try {
    await connection.beginTransaction();
    const result = await callback(connection);
    await connection.commit();
    return result;
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
}

module.exports = {
  initPool,
  getConnection,
  query,
  queryOne,
  testConnection,
  closePool,
  transaction
};
