/**
 * Database Migration Script
 * Applies SQL migrations to the database
 */

require('dotenv').config();
const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');

async function runMigration() {
  console.log('🚀 Starting database migration...\n');

  // Create connection
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT) || 3306,
    user: process.env.DB_USER,
    password: process.env.DB_PASS,
    database: process.env.DB_NAME,
    multipleStatements: true
  });

  try {
    console.log('✓ Connected to database');

    // Read migration file
    const migrationPath = path.join(__dirname, '../migrations/001_schema.sql');
    const sql = fs.readFileSync(migrationPath, 'utf8');

    console.log('✓ Migration file loaded');
    console.log('⏳ Applying migration...\n');

    // Execute migration
    await connection.query(sql);

    console.log('✓ Migration completed successfully!\n');
  } catch (error) {
    console.error('✗ Migration failed:', error.message);
    process.exit(1);
  } finally {
    await connection.end();
  }
}

// Run migration
runMigration().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
