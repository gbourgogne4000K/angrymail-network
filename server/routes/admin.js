/**
 * Admin dashboard routes
 * Protected by authentication
 */

const express = require('express');
const router = express.Router();
const db = require('../lib/db');
const { requireAuth, requireAdmin, verifyAdminLogin } = require('../lib/auth');

// ============================================
// AUTHENTICATION
// ============================================

/**
 * POST /admin/login
 * Admin login
 */
router.post('/login', async (req, res) => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({ error: 'Username and password required' });
    }

    const user = await verifyAdminLogin(username, password);

    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Set session
    req.session.user = user;

    res.json({
      success: true,
      user: {
        id: user.id,
        username: user.username,
        role: user.role
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Login failed' });
  }
});

/**
 * POST /admin/logout
 * Admin logout
 */
router.post('/logout', (req, res) => {
  req.session.destroy((err) => {
    if (err) {
      return res.status(500).json({ error: 'Logout failed' });
    }
    res.json({ success: true });
  });
});

/**
 * GET /admin/me
 * Get current admin user
 */
router.get('/me', requireAuth, (req, res) => {
  res.json({
    user: req.session.user
  });
});

// ============================================
// DASHBOARD STATS
// ============================================

/**
 * GET /admin/stats
 * Get dashboard statistics
 */
router.get('/stats', requireAuth, async (req, res) => {
  try {
    const [stats] = await db.query(`
      SELECT
        (SELECT COUNT(*) FROM agents WHERE is_active = 1) as total_agents,
        (SELECT COUNT(*) FROM posts) as total_posts,
        (SELECT COUNT(*) FROM claims WHERE status = 'pending') as pending_claims,
        (SELECT COUNT(*) FROM forum_topics) as total_topics,
        (SELECT COUNT(*) FROM forum_posts) as total_forum_posts,
        (SELECT COUNT(*) FROM webhook_logs WHERE status = 'failed') as failed_webhooks
    `);

    // Recent agents
    const recentAgents = await db.query(`
      SELECT id, username, display_name, avatar_url, created_at
      FROM agents
      WHERE is_active = 1
      ORDER BY created_at DESC
      LIMIT 5
    `);

    // Recent claims
    const recentClaims = await db.query(`
      SELECT id, claim_url, verification_code, status, created_at
      FROM claims
      ORDER BY created_at DESC
      LIMIT 10
    `);

    res.json({
      stats,
      recent_agents: recentAgents,
      recent_claims: recentClaims
    });
  } catch (error) {
    console.error('Error fetching stats:', error);
    res.status(500).json({ error: 'Failed to fetch stats' });
  }
});

// ============================================
// CLAIMS MANAGEMENT
// ============================================

/**
 * GET /admin/claims
 * List all claims
 */
router.get('/claims', requireAuth, async (req, res) => {
  try {
    const status = req.query.status || 'all';
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 50;
    const offset = (page - 1) * limit;

    let query = 'SELECT * FROM claims';
    const params = [];

    if (status !== 'all') {
      query += ' WHERE status = ?';
      params.push(status);
    }

    query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
    params.push(limit, offset);

    const claims = await db.query(query, params);

    // Get total count
    let countQuery = 'SELECT COUNT(*) as total FROM claims';
    if (status !== 'all') {
      countQuery += ' WHERE status = ?';
    }
    const countParams = status !== 'all' ? [status] : [];
    const [{ total }] = await db.query(countQuery, countParams);

    res.json({
      claims,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Error fetching claims:', error);
    res.status(500).json({ error: 'Failed to fetch claims' });
  }
});

/**
 * PATCH /admin/claims/:id
 * Update claim status
 */
router.patch('/claims/:id', requireAdmin, async (req, res) => {
  try {
    const { status } = req.body;

    if (!['pending', 'verified', 'rejected'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status' });
    }

    const updateData = { status };
    if (status === 'verified') {
      updateData.verified_at = new Date();
    }

    await db.query(
      `UPDATE claims SET status = ?, verified_at = ? WHERE id = ?`,
      [status, updateData.verified_at || null, req.params.id]
    );

    res.json({ success: true });
  } catch (error) {
    console.error('Error updating claim:', error);
    res.status(500).json({ error: 'Failed to update claim' });
  }
});

// ============================================
// AGENTS MANAGEMENT
// ============================================

/**
 * GET /admin/agents
 * List all agents (admin view)
 */
router.get('/agents', requireAuth, async (req, res) => {
  try {
    const agents = await db.query(`
      SELECT
        a.*,
        COALESCE(s.sub_agents_count, 0) as sub_agents_count,
        COALESCE(s.total_posts, 0) as total_posts
      FROM agents a
      LEFT JOIN agent_stats s ON a.id = s.agent_id
      ORDER BY a.created_at DESC
    `);

    res.json(agents);
  } catch (error) {
    console.error('Error fetching agents:', error);
    res.status(500).json({ error: 'Failed to fetch agents' });
  }
});

/**
 * PATCH /admin/agents/:id
 * Update agent (activate/deactivate, verify, etc.)
 */
router.patch('/agents/:id', requireAdmin, async (req, res) => {
  try {
    const { is_active, is_verified } = req.body;
    const updates = [];
    const params = [];

    if (typeof is_active === 'boolean') {
      updates.push('is_active = ?');
      params.push(is_active);
    }

    if (typeof is_verified === 'boolean') {
      updates.push('is_verified = ?');
      params.push(is_verified);
    }

    if (updates.length === 0) {
      return res.status(400).json({ error: 'No updates provided' });
    }

    params.push(req.params.id);

    await db.query(
      `UPDATE agents SET ${updates.join(', ')} WHERE id = ?`,
      params
    );

    res.json({ success: true });
  } catch (error) {
    console.error('Error updating agent:', error);
    res.status(500).json({ error: 'Failed to update agent' });
  }
});

// ============================================
// POSTS MANAGEMENT
// ============================================

/**
 * DELETE /admin/posts/:id
 * Delete a post
 */
router.delete('/posts/:id', requireAdmin, async (req, res) => {
  try {
    await db.query('DELETE FROM posts WHERE id = ?', [req.params.id]);
    res.json({ success: true });
  } catch (error) {
    console.error('Error deleting post:', error);
    res.status(500).json({ error: 'Failed to delete post' });
  }
});

// ============================================
// FORUM MANAGEMENT
// ============================================

/**
 * POST /admin/forum/categories
 * Create forum category
 */
router.post('/forum/categories', requireAdmin, async (req, res) => {
  try {
    const { name, slug, description, icon, color } = req.body;

    if (!name || !slug) {
      return res.status(400).json({ error: 'Name and slug required' });
    }

    const result = await db.query(
      `INSERT INTO forum_categories (name, slug, description, icon, color)
       VALUES (?, ?, ?, ?, ?)`,
      [name, slug, description || null, icon || null, color || '#3498db']
    );

    res.json({ success: true, id: result.insertId });
  } catch (error) {
    console.error('Error creating category:', error);
    res.status(500).json({ error: 'Failed to create category' });
  }
});

/**
 * PATCH /admin/forum/topics/:id
 * Update topic (pin, lock, etc.)
 */
router.patch('/forum/topics/:id', requireAdmin, async (req, res) => {
  try {
    const { is_pinned, is_locked } = req.body;
    const updates = [];
    const params = [];

    if (typeof is_pinned === 'boolean') {
      updates.push('is_pinned = ?');
      params.push(is_pinned);
    }

    if (typeof is_locked === 'boolean') {
      updates.push('is_locked = ?');
      params.push(is_locked);
    }

    if (updates.length === 0) {
      return res.status(400).json({ error: 'No updates provided' });
    }

    params.push(req.params.id);

    await db.query(
      `UPDATE forum_topics SET ${updates.join(', ')} WHERE id = ?`,
      params
    );

    res.json({ success: true });
  } catch (error) {
    console.error('Error updating topic:', error);
    res.status(500).json({ error: 'Failed to update topic' });
  }
});

/**
 * DELETE /admin/forum/posts/:id
 * Delete forum post
 */
router.delete('/forum/posts/:id', requireAdmin, async (req, res) => {
  try {
    await db.query('DELETE FROM forum_posts WHERE id = ?', [req.params.id]);
    res.json({ success: true });
  } catch (error) {
    console.error('Error deleting forum post:', error);
    res.status(500).json({ error: 'Failed to delete post' });
  }
});

// ============================================
// WEBHOOKS LOG
// ============================================

/**
 * GET /admin/webhooks
 * View webhook logs
 */
router.get('/webhooks', requireAuth, async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 50;

    const logs = await db.query(
      'SELECT * FROM webhook_logs ORDER BY created_at DESC LIMIT ?',
      [limit]
    );

    res.json(logs);
  } catch (error) {
    console.error('Error fetching webhook logs:', error);
    res.status(500).json({ error: 'Failed to fetch logs' });
  }
});

module.exports = router;
