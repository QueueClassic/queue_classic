DO $$DECLARE r record;
BEGIN
  BEGIN
    ALTER TABLE queue_classic_jobs ADD COLUMN scheduled_at timestamptz default now();
    CREATE INDEX idx_qc_on_scheduled_at_only_unlocked ON queue_classic_jobs (scheduled_at, id) WHERE locked_at IS NULL;
  EXCEPTION
    WHEN duplicate_column THEN RAISE NOTICE 'column scheduled_at already exists in queue_classic_jobs.';
  END;
END$$;
