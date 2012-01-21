--
-- return the given queue row, creating it if it does not exist
--
-- Usage: SELECT * from create_queue('myqueue');
--
CREATE OR REPLACE FUNCTION use_queue( queue text ) RETURNS queues AS $$
DECLARE
  new_row queues%ROWTYPE;
BEGIN
  SELECT * INTO new_row FROM queues WHERE name = queue;
  IF NOT FOUND THEN
    INSERT INTO queues(name) VALUES (queue) RETURNING * INTO new_row;
  END IF;
  RETURN new_row;
END;
$$ LANGUAGE plpgsql;

--
-- Return the number of rows in the jobs table for the given queue.
--
CREATE OR REPLACE FUNCTION queue_size( queue text ) RETURNS integer AS $$
DECLARE
  q_size integer;
BEGIN
  SELECT count(j.id) INTO q_size
    FROM jobs j
    JOIN queues q
      ON q.id = j.queue_id
   WHERE q.name = queue
  ;

  RETURN q_size;
END;
$$ LANGUAGE plpgsql;

--
--
-- Generate a unique identifier from the input and the application_name sequence
--
CREATE OR REPLACE FUNCTION application_id( stem text ) RETURNS text AS $$
DECLARE
  app_id text;
BEGIN
  SELECT stem || '-' || nextval('application_id_seq') INTO app_id;
  RETURN app_id;
END;
$$ LANGUAGE plpgsql;


--
-- Create a new msg on the given queue, if the queue does not exist, create it.
--
CREATE OR REPLACE FUNCTION put( queue text, msg text ) RETURNS jobs AS $$
DECLARE
  new_job   jobs%ROWTYPE;
  q_row     queues%ROWTYPE;
BEGIN
  SELECT * INTO q_row FROM use_queue( queue );
  INSERT INTO jobs(queue_id, payload) VALUES(q_row.id, msg) RETURNING * INTO new_job;
  RETURN new_job;
END;
$$ LANGUAGE plpgsql;

--
-- reserve a job off the queue, this means updating a few fields
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

  INSERT INTO jobs_history(id    , queue_id, payload              , ready_at              , reserved_at              , reserved_by              , finalized_message)
       VALUES             (job_id, qid     , finalized_job.payload, finalized_job.ready_at, finalized_job.reserved_at, finalized_job.reserved_by, message )
    RETURNING *
         INTO historical_job;
  RETURN historical_job;
END;
$$ LANGUAGE plpgsql;

