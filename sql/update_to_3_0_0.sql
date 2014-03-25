DO $$DECLARE r record;
BEGIN
	BEGIN
		ALTER TABLE queue_classic_jobs ADD COLUMN created_at timestamptz default now();
	EXCEPTION
		WHEN duplicate_column THEN RAISE NOTICE 'column created_at already exists in queue_classic_jobs.';
	END;
END$$;

DO $$DECLARE r record;
BEGIN
  BEGIN
    ALTER TABLE queue_classic_jobs ADD COLUMN locked_by integer;
  EXCEPTION
    WHEN duplicate_column THEN RAISE NOTICE 'column locked_by already exists in queue_classic_jobs.';
  END;
END$$;
