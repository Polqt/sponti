-- Migration: Enable required extensions
-- Extensions must be enabled before any tables or functions that depend on them.

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
