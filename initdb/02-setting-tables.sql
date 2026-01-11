-- 02-setting-tables.sql
-- Create the events.setting and other.setting tables at cluster initialization

\connect misc

-- Ensure schemas exist
CREATE SCHEMA IF NOT EXISTS events;
CREATE SCHEMA IF NOT EXISTS other;

-- ----------------------------
-- Tables
-- ----------------------------
CREATE TABLE IF NOT EXISTS events.setting (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  key text NOT NULL,
  description text NOT NULL,
  value text NOT NULL,
  date_insert timestamptz NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
  date_update timestamptz NOT NULL DEFAULT (now() AT TIME ZONE 'utc')
);

CREATE TABLE IF NOT EXISTS other.setting (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  key text NOT NULL,
  description text NOT NULL,
  value text NOT NULL,
  date_insert timestamptz NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
  date_update timestamptz NOT NULL DEFAULT (now() AT TIME ZONE 'utc')
);

-- ----------------------------
-- Enforce uniqueness of setting keys
-- ----------------------------
CREATE UNIQUE INDEX IF NOT EXISTS ux_events_setting_key
  ON events.setting (key);

CREATE UNIQUE INDEX IF NOT EXISTS ux_other_setting_key
  ON other.setting (key);

-- ----------------------------
-- Ensure schema_version exists (UPSERT)
-- ----------------------------

INSERT INTO events.setting (key, description, value)
VALUES ('schema_version', 'Schema version', '1')
ON CONFLICT (key) DO NOTHING;

INSERT INTO other.setting (key, description, value)
VALUES ('schema_version', 'Schema version', '1')
ON CONFLICT (key) DO NOTHING;
