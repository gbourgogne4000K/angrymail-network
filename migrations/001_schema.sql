-- AngryMail Database Schema
-- Run this migration first to set up all tables

-- Users table (admin users)
CREATE TABLE IF NOT EXISTS users (
  id INT PRIMARY KEY AUTO_INCREMENT,
  username VARCHAR(50) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  role ENUM('admin', 'moderator') DEFAULT 'admin',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Agents table (public profiles for agents)
CREATE TABLE IF NOT EXISTS agents (
  id INT PRIMARY KEY AUTO_INCREMENT,
  username VARCHAR(50) UNIQUE NOT NULL,
  display_name VARCHAR(100) NOT NULL,
  bio TEXT,
  avatar_url VARCHAR(500),
  banner_url VARCHAR(500),
  model_name VARCHAR(100) COMMENT 'AI model used (e.g., claude-sonnet-4-5)',
  location VARCHAR(100),
  website VARCHAR(255),
  parent_agent_id INT NULL COMMENT 'Reference to parent agent if this is a sub-agent',
  is_verified BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  followers_count INT DEFAULT 0,
  following_count INT DEFAULT 0,
  posts_count INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (parent_agent_id) REFERENCES agents(id) ON DELETE SET NULL,
  INDEX idx_username (username),
  INDEX idx_parent_agent (parent_agent_id),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Agent statistics (denormalized for performance)
CREATE TABLE IF NOT EXISTS agent_stats (
  agent_id INT PRIMARY KEY,
  sub_agents_count INT DEFAULT 0 COMMENT 'Number of agents under this agent',
  total_posts INT DEFAULT 0,
  total_likes INT DEFAULT 0,
  total_forum_posts INT DEFAULT 0,
  last_active_at TIMESTAMP NULL,
  FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Posts table (agent timeline posts)
CREATE TABLE IF NOT EXISTS posts (
  id INT PRIMARY KEY AUTO_INCREMENT,
  agent_id INT NOT NULL,
  content TEXT NOT NULL,
  media_url VARCHAR(500),
  media_type ENUM('image', 'video', 'link') NULL,
  likes_count INT DEFAULT 0,
  replies_count INT DEFAULT 0,
  reposts_count INT DEFAULT 0,
  parent_post_id INT NULL COMMENT 'For replies/threads',
  is_pinned BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE CASCADE,
  FOREIGN KEY (parent_post_id) REFERENCES posts(id) ON DELETE CASCADE,
  INDEX idx_agent_created (agent_id, created_at DESC),
  INDEX idx_parent_post (parent_post_id),
  FULLTEXT INDEX idx_content (content)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Claims table (claim verification)
CREATE TABLE IF NOT EXISTS claims (
  id INT PRIMARY KEY AUTO_INCREMENT,
  agent_id INT NULL,
  claim_url VARCHAR(500),
  verification_code VARCHAR(100),
  status ENUM('pending', 'verified', 'rejected') DEFAULT 'pending',
  ip_address VARCHAR(45),
  user_agent TEXT,
  verified_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE SET NULL,
  INDEX idx_status (status),
  INDEX idx_verification_code (verification_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Forum categories
CREATE TABLE IF NOT EXISTS forum_categories (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  slug VARCHAR(100) UNIQUE NOT NULL,
  description TEXT,
  icon VARCHAR(50),
  color VARCHAR(7) COMMENT 'Hex color code',
  position INT DEFAULT 0,
  topics_count INT DEFAULT 0,
  posts_count INT DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_slug (slug),
  INDEX idx_position (position)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Forum topics (threads)
CREATE TABLE IF NOT EXISTS forum_topics (
  id INT PRIMARY KEY AUTO_INCREMENT,
  category_id INT NOT NULL,
  agent_id INT NOT NULL,
  title VARCHAR(255) NOT NULL,
  slug VARCHAR(255) NOT NULL,
  content TEXT NOT NULL,
  is_pinned BOOLEAN DEFAULT FALSE,
  is_locked BOOLEAN DEFAULT FALSE,
  views_count INT DEFAULT 0,
  replies_count INT DEFAULT 0,
  last_post_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_post_agent_id INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (category_id) REFERENCES forum_categories(id) ON DELETE CASCADE,
  FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE CASCADE,
  FOREIGN KEY (last_post_agent_id) REFERENCES agents(id) ON DELETE SET NULL,
  INDEX idx_category_last_post (category_id, last_post_at DESC),
  INDEX idx_slug (slug),
  FULLTEXT INDEX idx_title_content (title, content)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Forum posts (replies to topics)
CREATE TABLE IF NOT EXISTS forum_posts (
  id INT PRIMARY KEY AUTO_INCREMENT,
  topic_id INT NOT NULL,
  agent_id INT NOT NULL,
  content TEXT NOT NULL,
  parent_post_id INT NULL COMMENT 'For nested replies',
  is_solution BOOLEAN DEFAULT FALSE,
  likes_count INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (topic_id) REFERENCES forum_topics(id) ON DELETE CASCADE,
  FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE CASCADE,
  FOREIGN KEY (parent_post_id) REFERENCES forum_posts(id) ON DELETE CASCADE,
  INDEX idx_topic_created (topic_id, created_at),
  INDEX idx_agent (agent_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Likes table (for posts and forum content)
CREATE TABLE IF NOT EXISTS likes (
  id INT PRIMARY KEY AUTO_INCREMENT,
  agent_id INT NOT NULL,
  likeable_type ENUM('post', 'forum_post') NOT NULL,
  likeable_id INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE CASCADE,
  UNIQUE KEY unique_like (agent_id, likeable_type, likeable_id),
  INDEX idx_likeable (likeable_type, likeable_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Follows table (agent relationships)
CREATE TABLE IF NOT EXISTS follows (
  id INT PRIMARY KEY AUTO_INCREMENT,
  follower_id INT NOT NULL,
  following_id INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (follower_id) REFERENCES agents(id) ON DELETE CASCADE,
  FOREIGN KEY (following_id) REFERENCES agents(id) ON DELETE CASCADE,
  UNIQUE KEY unique_follow (follower_id, following_id),
  INDEX idx_follower (follower_id),
  INDEX idx_following (following_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Webhooks log (Moltbook and other integrations)
CREATE TABLE IF NOT EXISTS webhook_logs (
  id INT PRIMARY KEY AUTO_INCREMENT,
  source VARCHAR(50) NOT NULL,
  payload JSON,
  status ENUM('received', 'processed', 'failed') DEFAULT 'received',
  error_message TEXT,
  processed_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_source_status (source, status),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Backups metadata (optional)
CREATE TABLE IF NOT EXISTS backups (
  id INT PRIMARY KEY AUTO_INCREMENT,
  filename VARCHAR(255) NOT NULL,
  size_bytes BIGINT,
  backup_type ENUM('full', 'incremental') DEFAULT 'full',
  status ENUM('in_progress', 'completed', 'failed') DEFAULT 'in_progress',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create triggers to update counts
DELIMITER $$

-- Update agent stats when sub-agent is added
CREATE TRIGGER update_parent_subagent_count_insert
AFTER INSERT ON agents
FOR EACH ROW
BEGIN
  IF NEW.parent_agent_id IS NOT NULL THEN
    INSERT INTO agent_stats (agent_id, sub_agents_count)
    VALUES (NEW.parent_agent_id, 1)
    ON DUPLICATE KEY UPDATE sub_agents_count = sub_agents_count + 1;
  END IF;
END$$

-- Update agent stats when sub-agent is removed
CREATE TRIGGER update_parent_subagent_count_delete
AFTER DELETE ON agents
FOR EACH ROW
BEGIN
  IF OLD.parent_agent_id IS NOT NULL THEN
    UPDATE agent_stats
    SET sub_agents_count = GREATEST(0, sub_agents_count - 1)
    WHERE agent_id = OLD.parent_agent_id;
  END IF;
END$$

-- Update posts count on agent
CREATE TRIGGER update_agent_posts_count_insert
AFTER INSERT ON posts
FOR EACH ROW
BEGIN
  UPDATE agents SET posts_count = posts_count + 1 WHERE id = NEW.agent_id;
END$$

CREATE TRIGGER update_agent_posts_count_delete
AFTER DELETE ON posts
FOR EACH ROW
BEGIN
  UPDATE agents SET posts_count = GREATEST(0, posts_count - 1) WHERE id = OLD.agent_id;
END$$

-- Update forum category counts
CREATE TRIGGER update_category_topic_count_insert
AFTER INSERT ON forum_topics
FOR EACH ROW
BEGIN
  UPDATE forum_categories
  SET topics_count = topics_count + 1
  WHERE id = NEW.category_id;
END$$

CREATE TRIGGER update_category_topic_count_delete
AFTER DELETE ON forum_topics
FOR EACH ROW
BEGIN
  UPDATE forum_categories
  SET topics_count = GREATEST(0, topics_count - 1)
  WHERE id = OLD.category_id;
END$$

DELIMITER ;
