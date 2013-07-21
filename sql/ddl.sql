-- We are declaring the return type to be queue_classic_jobs.
-- This is ok since I am assuming that all of the users added queues will
-- have identical columns to queue_classic_jobs.
-- When QC supports queues with columns other than the default, we will have to change this.

CREATE OR REPLACE FUNCTION lock_head(q_name varchar, top_boundary integer, worker_id bigint, worker_update_time int)
RETURNS SETOF queue_classic_jobs AS $$
DECLARE
  unlocked bigint;
  relative_top integer;
  job_count integer;
  unlock_stmt varchar;
BEGIN
  -- The purpose is to release contention for the first spot in the table.
  -- The select count(*) is going to slow down dequeue performance but allow
  -- for more workers. Would love to see some optimization here...

  EXECUTE 'SELECT count(*) FROM '
    || '(SELECT * FROM queue_classic_jobs WHERE q_name = '
    || quote_literal(q_name)
    || ' LIMIT '
    || quote_literal(top_boundary)
    || ') limited'
  INTO job_count;

  SELECT TRUNC(random() * (top_boundary - 1))
  INTO relative_top;

  IF job_count < top_boundary THEN
    relative_top = 0;
  END IF;

  LOOP
    BEGIN
      unlock_stmt = ' (locked_at IS NULL OR NOT EXISTS('
        || '   SELECT 1 FROM queue_classic_workers'
        || '   WHERE queue_classic_workers.id = locked_by AND'
        || '   last_seen < NOW() - INTERVAL''' || worker_update_time || ' seconds'''
        || ' ) AND q_name = ' || quote_literal(q_name) || ')';

      EXECUTE 'SELECT id FROM queue_classic_jobs '
        || ' WHERE ' || unlock_stmt
        || ' ORDER BY id ASC'
        || ' LIMIT 1'
        || ' OFFSET ' || quote_literal(relative_top)
        || ' FOR UPDATE NOWAIT'
      INTO unlocked;
      EXIT;
    EXCEPTION
      WHEN lock_not_available THEN
        -- do nothing. loop again and hope we get a lock
    END;
  END LOOP;

  RETURN QUERY EXECUTE 'UPDATE queue_classic_jobs'
    || ' SET locked_at = (CURRENT_TIMESTAMP),'
    || ' locked_by = $2'
    || ' WHERE id = $1'
    || ' AND ' || unlock_stmt
    || ' RETURNING *'
  USING unlocked, worker_id;

  RETURN;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION lock_head(tname varchar, worker_id bigint, worker_update_time int)
RETURNS SETOF queue_classic_jobs AS $$
BEGIN
  RETURN QUERY EXECUTE 'SELECT * FROM lock_head($1,10,$2,$3)' USING tname, worker_id, worker_update_time;
END;
$$ LANGUAGE plpgsql;
