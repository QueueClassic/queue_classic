-- We are declaring the return type to be queue_classic_jobs.
-- This is ok since I am assuming that all of the users added queues will
-- have identical columns to queue_classic_jobs.
-- When QC supports queues with columns other than the default, we will have to change this.

CREATE OR REPLACE FUNCTION lock_head(q_name varchar, top_boundary integer)
RETURNS SETOF queue_classic_jobs AS $$
DECLARE
  unlocked integer;
  relative_top integer;
  job_count integer;
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
      EXECUTE 'SELECT id FROM queue_classic_jobs '
        || ' WHERE locked_at IS NULL'
        || ' AND q_name = '
        || quote_literal(q_name)
        || ' ORDER BY priority DESC, id ASC'
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

  RETURN QUERY EXECUTE 'UPDATE queue_classic_jobs '
    || ' SET locked_at = (CURRENT_TIMESTAMP)'
    || ' WHERE id = $1'
    || ' AND locked_at is NULL'
    || ' RETURNING *'
  USING unlocked;

  RETURN;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION lock_head(tname varchar)
RETURNS SETOF queue_classic_jobs AS $$
BEGIN
  RETURN QUERY EXECUTE 'SELECT * FROM lock_head($1,10)' USING tname;
END;
$$ LANGUAGE plpgsql;
