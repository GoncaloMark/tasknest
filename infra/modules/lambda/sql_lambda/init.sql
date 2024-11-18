CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create the ENUM types
CREATE TYPE task_status AS ENUM ('TODO', 'IN_PROGRESS', 'DONE');
CREATE TYPE task_priority AS ENUM ('LOW', 'MEDIUM', 'HIGH');

-- Create the Users table
CREATE TABLE Users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE
);

-- Create the Tasks table
CREATE TABLE Tasks (
    task_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES Users(user_id) ON DELETE CASCADE,
    title VARCHAR(50) NOT NULL,
    description TEXT,
    creation_date DATE NOT NULL DEFAULT CURRENT_DATE,
    deadline DATE,
    status task_status NOT NULL,  -- Use the task_status ENUM type
    priority task_priority NOT NULL  -- Use the task_priority ENUM type
);
