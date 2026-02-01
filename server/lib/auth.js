/**
 * Authentication utilities
 * Handles password hashing and session management
 */

const bcrypt = require('bcrypt');
const db = require('./db');

const SALT_ROUNDS = 12;

/**
 * Hash a password
 */
async function hashPassword(password) {
  return await bcrypt.hash(password, SALT_ROUNDS);
}

/**
 * Verify password against hash
 */
async function verifyPassword(password, hash) {
  return await bcrypt.compare(password, hash);
}

/**
 * Create admin user if not exists
 */
async function ensureAdminUser() {
  const adminUser = process.env.ADMIN_USER;
  const adminPass = process.env.ADMIN_PASS;

  if (!adminUser || !adminPass) {
    console.warn('⚠ ADMIN_USER or ADMIN_PASS not set in .env');
    return;
  }

  try {
    // Check if admin exists
    const existing = await db.queryOne(
      'SELECT id FROM users WHERE username = ?',
      [adminUser]
    );

    if (!existing) {
      const hash = await hashPassword(adminPass);
      await db.query(
        'INSERT INTO users (username, password_hash, role) VALUES (?, ?, ?)',
        [adminUser, hash, 'admin']
      );
      console.log('✓ Admin user created:', adminUser);
    }
  } catch (error) {
    console.error('Error creating admin user:', error.message);
  }
}

/**
 * Verify admin credentials
 */
async function verifyAdminLogin(username, password) {
  try {
    const user = await db.queryOne(
      'SELECT id, username, password_hash, role FROM users WHERE username = ?',
      [username]
    );

    if (!user) {
      return null;
    }

    const valid = await verifyPassword(password, user.password_hash);
    if (!valid) {
      return null;
    }

    // Return user without password hash
    return {
      id: user.id,
      username: user.username,
      role: user.role
    };
  } catch (error) {
    console.error('Error verifying login:', error.message);
    return null;
  }
}

/**
 * Middleware to check if user is authenticated
 */
function requireAuth(req, res, next) {
  if (!req.session || !req.session.user) {
    return res.status(401).json({ error: 'Authentication required' });
  }
  next();
}

/**
 * Middleware to check if user is admin
 */
function requireAdmin(req, res, next) {
  if (!req.session || !req.session.user || req.session.user.role !== 'admin') {
    return res.status(403).json({ error: 'Admin access required' });
  }
  next();
}

module.exports = {
  hashPassword,
  verifyPassword,
  ensureAdminUser,
  verifyAdminLogin,
  requireAuth,
  requireAdmin
};
