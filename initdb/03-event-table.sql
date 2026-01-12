-- 03-event-table.sql
-- Create the events.event table at cluster initialization

\connect misc

DO $$
DECLARE
  v_events text;
BEGIN
  SELECT value INTO v_events
  FROM events.setting
  WHERE key = 'schema_version';

  -- -------------------------
  -- Migrations for events
  -- -------------------------
  IF v_events = '1' THEN
    -- Version 1: create events.event
    EXECUTE $sql$
      CREATE TABLE IF NOT EXISTS events.event (
        id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        name text NOT NULL UNIQUE,
        description text,
        date_insert timestamptz NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
        date_update timestamptz NOT NULL DEFAULT (now() AT TIME ZONE 'utc')
      )
    $sql$;

  ELSIF v_events = '2' THEN
    -- Version 2: do something else (placeholder)
    -- Example: add a new column (just as a demo)
    -- EXECUTE 'ALTER TABLE events.event ADD COLUMN IF NOT EXISTS source text';

    NULL;
  ELSE
    RAISE EXCEPTION 'Unsupported events.schema_version: %', v_events;
  END IF;

END $$;

