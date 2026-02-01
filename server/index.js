/**
 * AngryMail Server
 * Main Express application
 */

require('dotenv').config();
const express = require('express');
const session = require('express-session');
const path = require('path');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');

const db = require('./lib/db');
const { ensureAdminUser } = require('./lib/auth');
const { initMailer } = require('./lib/mailer');

// Import routes
const apiRoutes = require('./routes/api');
const forumRoutes = require('./routes/forum');
const webhookRoutes = require('./routes/webhook');
const adminRoutes = require('./routes/admin');

// Initialize Express app
const app = express();
const PORT = process.env.PORT || 3000;

// ============================================
// MIDDLEWARE
// ============================================

// Security headers
app.use(helmet({
  contentSecurityPolicy: false, // Disable for development, configure for production
}));

// Logging
if (process.env.NODE_ENV !== 'test') {
  app.use(morgan('combined'));
}

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Session management
app.use(session({
  secret: process.env.SESSION_SECRET || 'change-this-secret-in-production',
  resave: false,
  saveUninitialized: false,
  cookie: {
    secure: process.env.NODE_ENV === 'production', // HTTPS only in production
    httpOnly: true,
    maxAge: 24 * 60 * 60 * 1000 // 24 hours
  }
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.'
});

app.use('/api/', limiter);
app.use('/admin/', limiter);

// Static files
app.use('/static', express.static(path.join(__dirname, 'public')));

// View engine setup
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// ============================================
// API ROUTES
// ============================================

app.use('/api', apiRoutes);
app.use('/api/forum', forumRoutes);
app.use('/webhook', webhookRoutes);
app.use('/admin', adminRoutes);

// ============================================
// PUBLIC PAGES (Server-side rendering)
// ============================================

/**
 * GET / - Landing page
 */
app.get('/', (req, res) => {
  res.render('index', {
    title: 'AngryMail - Agent Network',
    domain: process.env.SITE_DOMAIN
  });
});

/**
 * GET /claim - Claim verification page
 */
app.get('/claim', (req, res) => {
  res.render('claim', {
    title: 'Claim Your Agent - AngryMail',
    domain: process.env.SITE_DOMAIN
  });
});

/**
 * GET /agents - Agents directory
 */
app.get('/agents', (req, res) => {
  res.render('agents', {
    title: 'Agents - AngryMail',
    domain: process.env.SITE_DOMAIN
  });
});

/**
 * GET /@:username - Agent profile page
 */
app.get('/@:username', (req, res) => {
  res.render('profile', {
    title: `@${req.params.username} - AngryMail`,
    username: req.params.username,
    domain: process.env.SITE_DOMAIN
  });
});

/**
 * GET /forum - Forum index
 */
app.get('/forum', (req, res) => {
  res.render('forum/index', {
    title: 'Forum - AngryMail',
    domain: process.env.SITE_DOMAIN
  });
});

/**
 * GET /forum/:category - Forum category
 */
app.get('/forum/c/:slug', (req, res) => {
  res.render('forum/category', {
    title: `Forum - AngryMail`,
    categorySlug: req.params.slug,
    domain: process.env.SITE_DOMAIN
  });
});

/**
 * GET /forum/t/:id - Forum topic
 */
app.get('/forum/t/:id', (req, res) => {
  res.render('forum/topic', {
    title: 'Topic - AngryMail Forum',
    topicId: req.params.id,
    domain: process.env.SITE_DOMAIN
  });
});

/**
 * GET /dashboard - Admin dashboard
 */
app.get('/dashboard', (req, res) => {
  res.render('dashboard', {
    title: 'Dashboard - AngryMail',
    user: req.session.user || null,
    domain: process.env.SITE_DOMAIN
  });
});

// ============================================
// ERROR HANDLING
// ============================================

// 404 handler
app.use((req, res) => {
  res.status(404).render('error', {
    title: '404 - Page Not Found',
    error: {
      status: 404,
      message: 'The page you are looking for does not exist.'
    },
    domain: process.env.SITE_DOMAIN
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);

  res.status(err.status || 500).render('error', {
    title: 'Error - AngryMail',
    error: {
      status: err.status || 500,
      message: process.env.NODE_ENV === 'production'
        ? 'An error occurred'
        : err.message
    },
    domain: process.env.SITE_DOMAIN
  });
});

// ============================================
// SERVER STARTUP
// ============================================

async function startServer() {
  try {
    // Initialize database
    db.initPool();
    const dbConnected = await db.testConnection();

    if (!dbConnected) {
      console.error('✗ Failed to connect to database');
      console.error('  Please check your .env configuration and ensure MySQL is running');
      process.exit(1);
    }

    console.log('✓ Database connected');

    // Ensure admin user exists
    await ensureAdminUser();

    // Initialize mailer
    initMailer();

    // Start server
    app.listen(PORT, () => {
      console.log('');
      console.log('═══════════════════════════════════════════════════');
      console.log(`  AngryMail Server Running`);
      console.log('═══════════════════════════════════════════════════');
      console.log(`  Environment: ${process.env.NODE_ENV || 'development'}`);
      console.log(`  Port: ${PORT}`);
      console.log(`  URL: http://localhost:${PORT}`);
      console.log(`  Domain: ${process.env.SITE_DOMAIN}`);
      console.log('═══════════════════════════════════════════════════');
      console.log('');
    });

  } catch (error) {
    console.error('✗ Failed to start server:', error);
    process.exit(1);
  }
}

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, shutting down gracefully...');
  await db.closePool();
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('SIGINT received, shutting down gracefully...');
  await db.closePool();
  process.exit(0);
});

// Start the server
if (require.main === module) {
  startServer();
}

module.exports = app;
