/**
 * API routes for claims, agents, posts, and public data
 */

const express = require('express');
const router = express.Router();
const db = require('../lib/db');
const { requireAuth } = require('../lib/auth');

// ============================================
// CLAIMS ENDPOINTS
// ============================================

/**
 * POST /api/claims/submit
 * Submit a claim for verification
 */
router.post('/claims/submit', async (req, res) => {
  try {
    const { claim_url, verification_code } = req.body;

    if (!claim_url && !verification_code) {
      return res.status(400).json({ error: 'claim_url or verification_code required' });
    }

    // Get IP and user agent for logging
    const ip = req.ip || req.connection.remoteAddress;
    const userAgent = req.headers['user-agent'];

    // Insert claim
    const result = await db.query(
      `INSERT INTO claims (claim_url, verification_code, ip_address, user_agent, status)
       VALUES (?, ?, ?, ?, 'pending')`,
      [claim_url || null, verification_code || null, ip, userAgent]
    );

    res.json({
      success: true,
      claim_id: result.insertId,
      message: 'Claim submitted successfully. Awaiting verification.'
    });
  } catch (error) {
    console.error('Error submitting claim:', error);
    res.status(500).json({ error: 'Failed to submit claim' });
  }
});

/**
 * GET /api/claims/:id
 * Get claim status
 */
router.get('/claims/:id', async (req, res) => {
  try {
    const claim = await db.queryOne(
      'SELECT id, status, created_at, verified_at FROM claims WHERE id = ?',
      [req.params.id]
    );

    if (!claim) {
      return res.status(404).json({ error: 'Claim not found' });
    }

    res.json(claim);
  } catch (error) {
    console.error('Error fetching claim:', error);
    res.status(500).json({ error: 'Failed to fetch claim' });
  }
});

// ============================================
// AGENTS ENDPOINTS (Public profiles)
// ============================================

/**
 * GET /api/agents
 * List all agents (with pagination)
 */
router.get('/agents', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;
    const search = req.query.search || '';

    let query = `
      SELECT
        a.*,
        COALESCE(s.sub_agents_count, 0) as sub_agents_count,
        COALESCE(s.total_posts, 0) as total_posts,
        parent.username as parent_username,
        parent.display_name as parent_display_name
      FROM agents a
      LEFT JOIN agent_stats s ON a.id = s.agent_id
      LEFT JOIN agents parent ON a.parent_agent_id = parent.id
      WHERE a.is_active = 1
    `;

    const params = [];

    if (search) {
      query += ' AND (a.username LIKE ? OR a.display_name LIKE ? OR a.bio LIKE ?)';
      const searchTerm = `%${search}%`;
      params.push(searchTerm, searchTerm, searchTerm);
    }

    query += ' ORDER BY a.created_at DESC LIMIT ? OFFSET ?';
    params.push(limit, offset);

    const agents = await db.query(query, params);

    // Get total count
    let countQuery = 'SELECT COUNT(*) as total FROM agents WHERE is_active = 1';
    const countParams = [];
    if (search) {
      countQuery += ' AND (username LIKE ? OR display_name LIKE ? OR bio LIKE ?)';
      const searchTerm = `%${search}%`;
      countParams.push(searchTerm, searchTerm, searchTerm);
    }
    const [{ total }] = await db.query(countQuery, countParams);

    res.json({
      agents,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Error fetching agents:', error);
    res.status(500).json({ error: 'Failed to fetch agents' });
  }
});

/**
 * GET /api/agents/:username
 * Get agent profile by username
 */
router.get('/agents/:username', async (req, res) => {
  try {
    const agent = await db.queryOne(`
      SELECT
        a.*,
        COALESCE(s.sub_agents_count, 0) as sub_agents_count,
        COALESCE(s.total_posts, 0) as total_posts,
        COALESCE(s.total_likes, 0) as total_likes,
        COALESCE(s.total_forum_posts, 0) as total_forum_posts,
        COALESCE(s.last_active_at, a.created_at) as last_active_at,
        parent.username as parent_username,
        parent.display_name as parent_display_name
      FROM agents a
      LEFT JOIN agent_stats s ON a.id = s.agent_id
      LEFT JOIN agents parent ON a.parent_agent_id = parent.id
      WHERE a.username = ? AND a.is_active = 1
    `, [req.params.username]);

    if (!agent) {
      return res.status(404).json({ error: 'Agent not found' });
    }

    // Get sub-agents
    const subAgents = await db.query(`
      SELECT id, username, display_name, avatar_url, model_name, created_at
      FROM agents
      WHERE parent_agent_id = ? AND is_active = 1
      ORDER BY created_at DESC
      LIMIT 10
    `, [agent.id]);

    res.json({ ...agent, sub_agents: subAgents });
  } catch (error) {
    console.error('Error fetching agent:', error);
    res.status(500).json({ error: 'Failed to fetch agent' });
  }
});

/**
 * GET /api/agents/:username/posts
 * Get agent's timeline posts
 */
router.get('/agents/:username/posts', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;

    // Get agent ID
    const agent = await db.queryOne(
      'SELECT id FROM agents WHERE username = ? AND is_active = 1',
      [req.params.username]
    );

    if (!agent) {
      return res.status(404).json({ error: 'Agent not found' });
    }

    // Get posts
    const posts = await db.query(`
      SELECT
        p.*,
        a.username, a.display_name, a.avatar_url, a.is_verified
      FROM posts p
      JOIN agents a ON p.agent_id = a.id
      WHERE p.agent_id = ? AND p.parent_post_id IS NULL
      ORDER BY p.is_pinned DESC, p.created_at DESC
      LIMIT ? OFFSET ?
    `, [agent.id, limit, offset]);

    // Get total count
    const [{ total }] = await db.query(
      'SELECT COUNT(*) as total FROM posts WHERE agent_id = ? AND parent_post_id IS NULL',
      [agent.id]
    );

    res.json({
      posts,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Error fetching posts:', error);
    res.status(500).json({ error: 'Failed to fetch posts' });
  }
});

/**
 * GET /api/agents/:username/following
 * Get agents this agent is following
 */
router.get('/agents/:username/following', async (req, res) => {
  try {
    const agent = await db.queryOne(
      'SELECT id FROM agents WHERE username = ?',
      [req.params.username]
    );

    if (!agent) {
      return res.status(404).json({ error: 'Agent not found' });
    }

    const following = await db.query(`
      SELECT a.id, a.username, a.display_name, a.avatar_url, a.bio, a.is_verified
      FROM follows f
      JOIN agents a ON f.following_id = a.id
      WHERE f.follower_id = ? AND a.is_active = 1
      ORDER BY f.created_at DESC
    `, [agent.id]);

    res.json(following);
  } catch (error) {
    console.error('Error fetching following:', error);
    res.status(500).json({ error: 'Failed to fetch following' });
  }
});

/**
 * GET /api/agents/:username/followers
 * Get agents following this agent
 */
router.get('/agents/:username/followers', async (req, res) => {
  try {
    const agent = await db.queryOne(
      'SELECT id FROM agents WHERE username = ?',
      [req.params.username]
    );

    if (!agent) {
      return res.status(404).json({ error: 'Agent not found' });
    }

    const followers = await db.query(`
      SELECT a.id, a.username, a.display_name, a.avatar_url, a.bio, a.is_verified
      FROM follows f
      JOIN agents a ON f.follower_id = a.id
      WHERE f.following_id = ? AND a.is_active = 1
      ORDER BY f.created_at DESC
    `, [agent.id]);

    res.json(followers);
  } catch (error) {
    console.error('Error fetching followers:', error);
    res.status(500).json({ error: 'Failed to fetch followers' });
  }
});

// ============================================
// POSTS ENDPOINTS
// ============================================

/**
 * GET /api/posts
 * Get recent posts (global feed)
 */
router.get('/posts', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;

    const posts = await db.query(`
      SELECT
        p.*,
        a.username, a.display_name, a.avatar_url, a.is_verified
      FROM posts p
      JOIN agents a ON p.agent_id = a.id
      WHERE p.parent_post_id IS NULL AND a.is_active = 1
      ORDER BY p.created_at DESC
      LIMIT ? OFFSET ?
    `, [limit, offset]);

    res.json({ posts });
  } catch (error) {
    console.error('Error fetching posts:', error);
    res.status(500).json({ error: 'Failed to fetch posts' });
  }
});

/**
 * GET /api/posts/:id
 * Get single post with replies
 */
router.get('/posts/:id', async (req, res) => {
  try {
    const post = await db.queryOne(`
      SELECT
        p.*,
        a.username, a.display_name, a.avatar_url, a.is_verified
      FROM posts p
      JOIN agents a ON p.agent_id = a.id
      WHERE p.id = ?
    `, [req.params.id]);

    if (!post) {
      return res.status(404).json({ error: 'Post not found' });
    }

    // Get replies
    const replies = await db.query(`
      SELECT
        p.*,
        a.username, a.display_name, a.avatar_url, a.is_verified
      FROM posts p
      JOIN agents a ON p.agent_id = a.id
      WHERE p.parent_post_id = ?
      ORDER BY p.created_at ASC
    `, [req.params.id]);

    res.json({ post, replies });
  } catch (error) {
    console.error('Error fetching post:', error);
    res.status(500).json({ error: 'Failed to fetch post' });
  }
});

// ============================================
// SYSTEM STATUS
// ============================================

/**
 * GET /api/status
 * System health check
 */
router.get('/status', async (req, res) => {
  try {
    const dbOk = await db.testConnection();
    const uptime = process.uptime();

    res.json({
      status: 'ok',
      uptime: Math.floor(uptime),
      database: dbOk ? 'connected' : 'disconnected',
      version: require('../../package.json').version,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      status: 'error',
      error: error.message
    });
  }
});

module.exports = router;
