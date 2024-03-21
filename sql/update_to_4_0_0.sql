DO $$DECLARE r record;
BEGIN
  ALTER TABLE queue_classic_jobs ALTER COLUMN args TYPE jsonb USING args::jsonb;
  DROP FUNCTION IF EXISTS lock_head(tname varchar);
  DROP FUNCTION IF EXISTS lock_head(q_name varchar, top_boundary integer);
END$$;
