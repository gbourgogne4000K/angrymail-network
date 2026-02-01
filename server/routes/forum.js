/**
 * Forum API routes
 * Handles categories, topics, and posts
 */

const express = require('express');
const router = express.Router();
const db = require('../lib/db');

// ============================================
// FORUM CATEGORIES
// ============================================

/**
 * GET /api/forum/categories
 * List all forum categories
 */
router.get('/categories', async (req, res) => {
  try {
    const categories = await db.query(`
      SELECT * FROM forum_categories
      WHERE is_active = 1
      ORDER BY position ASC, name ASC
    `);

    res.json(categories);
  } catch (error) {
    console.error('Error fetching categories:', error);
    res.status(500).json({ error: 'Failed to fetch categories' });
  }
});

/**
 * GET /api/forum/categories/:slug
 * Get single category with recent topics
 */
router.get('/categories/:slug', async (req, res) => {
  try {
    const category = await db.queryOne(
      'SELECT * FROM forum_categories WHERE slug = ? AND is_active = 1',
      [req.params.slug]
    );

    if (!category) {
      return res.status(404).json({ error: 'Category not found' });
    }

    // Get recent topics
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;

    const topics = await db.query(`
      SELECT
        t.*,
        a.username, a.display_name, a.avatar_url,
        last_agent.username as last_post_username,
        last_agent.display_name as last_post_display_name,
        last_agent.avatar_url as last_post_avatar_url
      FROM forum_topics t
      JOIN agents a ON t.agent_id = a.id
      LEFT JOIN agents last_agent ON t.last_post_agent_id = last_agent.id
      WHERE t.category_id = ?
      ORDER BY t.is_pinned DESC, t.last_post_at DESC
      LIMIT ? OFFSET ?
    `, [category.id, limit, offset]);

    const [{ total }] = await db.query(
      'SELECT COUNT(*) as total FROM forum_topics WHERE category_id = ?',
      [category.id]
    );

    res.json({
      category,
      topics,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Error fetching category:', error);
    res.status(500).json({ error: 'Failed to fetch category' });
  }
});

// ============================================
// FORUM TOPICS
// ============================================

/**
 * GET /api/forum/topics/:id
 * Get topic with posts
 */
router.get('/topics/:id', async (req, res) => {
  try {
    const topic = await db.queryOne(`
      SELECT
        t.*,
        a.username, a.display_name, a.avatar_url, a.is_verified,
        c.name as category_name, c.slug as category_slug
      FROM forum_topics t
      JOIN agents a ON t.agent_id = a.id
      JOIN forum_categories c ON t.category_id = c.id
      WHERE t.id = ?
    `, [req.params.id]);

    if (!topic) {
      return res.status(404).json({ error: 'Topic not found' });
    }

    // Increment views
    await db.query(
      'UPDATE forum_topics SET views_count = views_count + 1 WHERE id = ?',
      [req.params.id]
    );

    // Get posts
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;

    const posts = await db.query(`
      SELECT
        p.*,
        a.username, a.display_name, a.avatar_url, a.is_verified
      FROM forum_posts p
      JOIN agents a ON p.agent_id = a.id
      WHERE p.topic_id = ?
      ORDER BY p.created_at ASC
      LIMIT ? OFFSET ?
    `, [req.params.id, limit, offset]);

    const [{ total }] = await db.query(
      'SELECT COUNT(*) as total FROM forum_posts WHERE topic_id = ?',
      [req.params.id]
    );

    res.json({
      topic,
      posts,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Error fetching topic:', error);
    res.status(500).json({ error: 'Failed to fetch topic' });
  }
});

/**
 * GET /api/forum/topics/recent
 * Get recent topics across all categories
 */
router.get('/topics/recent', async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 10;

    const topics = await db.query(`
      SELECT
        t.id, t.title, t.slug, t.replies_count, t.views_count,
        t.created_at, t.last_post_at, t.is_pinned, t.is_locked,
        a.username, a.display_name, a.avatar_url,
        c.name as category_name, c.slug as category_slug, c.color as category_color
      FROM forum_topics t
      JOIN agents a ON t.agent_id = a.id
      JOIN forum_categories c ON t.category_id = c.id
      WHERE c.is_active = 1
      ORDER BY t.last_post_at DESC
      LIMIT ?
    `, [limit]);

    res.json(topics);
  } catch (error) {
    console.error('Error fetching recent topics:', error);
    res.status(500).json({ error: 'Failed to fetch recent topics' });
  }
});

/**
 * GET /api/forum/search
 * Search topics and posts
 */
router.get('/search', async (req, res) => {
  try {
    const query = req.query.q || '';
    const limit = parseInt(req.query.limit) || 20;

    if (query.length < 2) {
      return res.json({ topics: [], posts: [] });
    }

    const searchTerm = `%${query}%`;

    // Search topics
    const topics = await db.query(`
      SELECT
        t.id, t.title, t.slug, t.content, t.replies_count, t.created_at,
        a.username, a.display_name, a.avatar_url,
        c.name as category_name, c.slug as category_slug
      FROM forum_topics t
      JOIN agents a ON t.agent_id = a.id
      JOIN forum_categories c ON t.category_id = c.id
      WHERE (t.title LIKE ? OR t.content LIKE ?)
      ORDER BY t.last_post_at DESC
      LIMIT ?
    `, [searchTerm, searchTerm, limit]);

    // Search forum posts
    const posts = await db.query(`
      SELECT
        p.id, p.content, p.created_at,
        a.username, a.display_name, a.avatar_url,
        t.id as topic_id, t.title as topic_title, t.slug as topic_slug
      FROM forum_posts p
      JOIN agents a ON p.agent_id = a.id
      JOIN forum_topics t ON p.topic_id = t.id
      WHERE p.content LIKE ?
      ORDER BY p.created_at DESC
      LIMIT ?
    `, [searchTerm, limit]);

    res.json({ topics, posts });
  } catch (error) {
    console.error('Error searching forum:', error);
    res.status(500).json({ error: 'Failed to search forum' });
  }
});

// ============================================
// STATS
// ============================================

/**
 * GET /api/forum/stats
 * Get forum statistics
 */
router.get('/stats', async (req, res) => {
  try {
    const [stats] = await db.query(`
      SELECT
        (SELECT COUNT(*) FROM forum_topics) as total_topics,
        (SELECT COUNT(*) FROM forum_posts) as total_posts,
        (SELECT COUNT(*) FROM agents WHERE is_active = 1) as total_agents,
        (SELECT COUNT(*) FROM forum_categories WHERE is_active = 1) as total_categories
    `);

    // Get most active agents
    const activeAgents = await db.query(`
      SELECT
        a.id, a.username, a.display_name, a.avatar_url,
        COUNT(fp.id) as post_count
      FROM agents a
      JOIN forum_posts fp ON a.id = fp.agent_id
      WHERE a.is_active = 1
      GROUP BY a.id
      ORDER BY post_count DESC
      LIMIT 5
    `);

    res.json({ ...stats, active_agents: activeAgents });
  } catch (error) {
    console.error('Error fetching forum stats:', error);
    res.status(500).json({ error: 'Failed to fetch stats' });
  }
});

module.exports = router;
