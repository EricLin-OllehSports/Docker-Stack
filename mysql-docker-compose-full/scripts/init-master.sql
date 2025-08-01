-- ================================================
-- MySQL Master Initialization Script
-- ================================================
-- This script creates the replication user for
-- MySQL master-slave replication setup.
-- ================================================

-- Create replication user with necessary privileges
CREATE USER IF NOT EXISTS 'repl'@'%'
  IDENTIFIED WITH mysql_native_password BY 'replpassword';

-- Grant replication privileges
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';

-- Apply changes
FLUSH PRIVILEGES;

-- Show created user (for verification)
SELECT User, Host FROM mysql.user WHERE User = 'repl';

-- Show master status (for reference)
SHOW MASTER STATUS;
