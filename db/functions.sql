--
-- Create a new worker identifier with the given prefix
--
CREATE OR REPLACE FUNCTION qc_worker( prefix text, separator text ) RETURNS text AS $$
DECLARE
  worker_id text;
BEGIN
  SELECT prefix || separator || current_date::text || separator || pg_backend_pid()::text INTO worker_id;
  RETURN worker_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION qc_worker() RETURNS text AS $$
BEGIN
  RETURN qc_worker( 'qc', '.' );
END;
$$ LANGUAGE plpgsql;

--
-- Create a new queue
--
-- Usage: SELECT * from create_queue('myqueue');
--
CREATE OR REPLACE FUNCTION create_queue( queue text ) RETURNS queues AS $$
DECLARE
  new_row queues%ROWTYPE;
BEGIN
  INSERT INTO queues(name) VALUES (queue) RETURNING * INTO new_row;
  RETURN new_row;
END;
$$ LANGUAGE plpgsql;

--
-- Create a new job on the given queue
--
CREATE OR REPLACE FUNCTION put( queue text, job_details text ) RETURNS jobs AS $$
DECLARE
  new_job   jobs%ROWTYPE;
  qid       integer;
BEGIN
  SELECT id INTO qid FROM queues WHERE name = queue;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Unable to fine queue "%"', queue;
  END IF;

  INSERT INTO jobs(queue_id, details) VALUES(qid, job_details) RETURNING * INTO new_job;
  RETURN new_job;
END;
$$ LANGUAGE plpgsql;

--
-- pull a job off the queue
--
CREATE OR REPLACE FUNCTION reserve( queue text, top_boundary integer, worker_id text ) RETURNS jobs AS $$
DECLARE
  reserved_job_id  integer;
  relative_top     integer;
  job_count        integer;
  qid              integer;
  reserved_job     jobs%ROWTYPE;
BEGIN
  -- Get the queue id
  SELECT id INTO qid FROM queues WHERE name = queue;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Unable to fine queue "%"', queue;
  END IF;


  -- Get the top range we are going to select from in the main query
  SELECT count(*) INTO job_count FROM jobs WHERE queue_id = qid;
  SELECT TRUNC( random() * top_boundary + 1 ) INTO relative_top;
  IF job_count < top_boundary THEN
    relative_top = 0;
  END IF;

  -- select for update a random job in the top_boundary range of the queue
  LOOP
    BEGIN
        SELECT id INTO reserved_job_id
          FROM jobs
         WHERE queue_id = qid
           AND reserved_at IS NULL
      ORDER BY id ASC
         LIMIT 1
        OFFSET relative_top
      FOR UPDATE
      NOWAIT;
      EXIT;
    EXCEPTION
      WHEN lock_not_available THEN
        -- do nothing. loop again and hope we get a lock
    END;
  END LOOP;

  -- update the reserved row
      UPDATE jobs
         SET reserved_at = (CURRENT_TIMESTAMP)
            ,reserved_by = worker_id
       WHERE id = reserved_job_id
   RETURNING *
        INTO reserved_job;


  RETURN reserved_job;
END;
$$ LANGUAGE plpgsql;

--
-- Shorthand function to use a default for the above function
--
CREATE OR REPLACE FUNCTION reserve( queue text ) RETURNS jobs AS $$
DECLARE
  reserved_job jobs%ROWTYPE;
BEGIN
  SELECT * INTO reserved_job FROM reserve(queue, 10);
  RETURN reserved_job;
END;
$$ LANGUAGE plpgsql;


--
-- finalize a job, this involves removing it from the job queue and inserting it into the job_history table
--
CREATE OR REPLACE FUNCTION finalize( queue text, job_id bigint, message text ) RETURNS jobs_history AS $$
DECLARE
  qid             integer;
  finalized_job   RECORD;
  historical_job  jobs_history%ROWTYPE;
BEGIN
  -- Get the queue id
  SELECT id INTO qid FROM queues WHERE name = queue;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Unable to fine queue "%"', queue;
  END IF;

  DELETE FROM jobs
        WHERE id = job_id
          AND reserved_at IS NOT NULL
    RETURNING * INTO finalized_job;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Unable to find job "%" in queue "%" that was reserved', job_id, queue;
  END IF;

  INSERT INTO jobs_history(id    , queue_id, details              , ready_at              , reserved_at              , reserved_by              , finalized_message)
       VALUES             (job_id, qid     , finalized_job.details, finalized_job.ready_at, finalized_job.reserved_at, finalized_job.reserved_by, message )
    RETURNING *
         INTO historical_job;
  RETURN historical_job;
END;
$$ LANGUAGE plpgsql;

