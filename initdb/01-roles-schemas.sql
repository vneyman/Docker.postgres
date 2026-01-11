-- 01-bootstrap.sql
-- Use PostgreSQL built-in roles for data access

\connect misc

-- ----------------------------
-- Create schemas
-- ----------------------------
CREATE SCHEMA IF NOT EXISTS events;
CREATE SCHEMA IF NOT EXISTS other;

-- ----------------------------
-- Create login roles (users)
-- ----------------------------
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'reader') THEN
    CREATE ROLE reader LOGIN PASSWORD 'reader_password';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app') THEN
    CREATE ROLE app LOGIN PASSWORD 'app_password';
  END IF;
END $$;

-- ----------------------------
-- Assign built-in privilege roles
-- ----------------------------

-- Reader: read-only everywhere
GRANT pg_read_all_data TO reader;

-- App: read + write everywhere (still no DDL)
GRANT pg_read_all_data TO app;
GRANT pg_write_all_data TO app;

-- Ensure privileges are inherited
ALTER ROLE reader INHERIT;
ALTER ROLE app INHERIT;

-- ----------------------------
-- Database-level hardening
-- ----------------------------

-- Allow connections
GRANT CONNECT ON DATABASE misc TO reader, app;

-- Optional: block temp tables
REVOKE TEMP ON DATABASE misc FROM PUBLIC;
REVOKE TEMP ON DATABASE misc FROM reader, app;

-- ----------------------------
-- Schema-level hardening (important)
-- ----------------------------

-- Prevent CREATE in application schemas
REVOKE CREATE ON SCHEMA events FROM PUBLIC;
REVOKE CREATE ON SCHEMA events FROM reader, app;

REVOKE CREATE ON SCHEMA other FROM PUBLIC;
REVOKE CREATE ON SCHEMA other FROM reader, app;

--  ----------------------------
-- Grant usage on schemas to roles
-- ----------------------------
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA events TO app, reader;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA other TO app, reader;
