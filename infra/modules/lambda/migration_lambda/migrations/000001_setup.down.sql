-- Drop the Tasks table first to remove foreign key constraints
DROP TABLE IF EXISTS Tasks;

-- Drop the Users table
DROP TABLE IF EXISTS Users;

-- Drop the ENUM types
DROP TYPE IF EXISTS task_status;
DROP TYPE IF EXISTS task_priority;

-- Remove the UUID extension
DROP EXTENSION IF EXISTS "uuid-ossp";