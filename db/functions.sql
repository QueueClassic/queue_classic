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
-- Return the number of rows in the messages table for the given queue.
--
CREATE OR REPLACE FUNCTION queue_size( queue text ) RETURNS integer AS $$
DECLARE
  q_size integer;
BEGIN
  SELECT count(j.id) INTO q_size
    FROM messages j
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
-- Create a new message on the given queue, if the queue does not exist, create it.
--
CREATE OR REPLACE FUNCTION put( queue text, message text ) RETURNS messages AS $$
DECLARE
  new_message   messages%ROWTYPE;
  q_row     queues%ROWTYPE;
BEGIN
  SELECT * INTO q_row FROM use_queue( queue );
  INSERT INTO messages(queue_id, payload) VALUES(q_row.id, message) RETURNING * INTO new_message;
  RETURN new_message;
END;
$$ LANGUAGE plpgsql;

--
-- reserve a message off the queue, this means updating a few fields
--
CREATE OR REPLACE FUNCTION reserve( qname text ) RETURNS messages AS $$
DECLARE
  reserved_message_id integer;
  relative_top        integer;
  message_count       integer;
  top_boundary        integer;
  queue               queues%ROWTYPE;
  reserved_message    messages%ROWTYPE;
BEGIN
  -- Get the queue id
  queue        = use_queue( qname );
  top_boundary = 10;
  message_count    = queue_ready_size( qname );

  SELECT TRUNC( random() * top_boundary + 1 ) INTO relative_top;
  IF message_count < top_boundary THEN
    relative_top = 0;
  END IF;

  -- select for update a random message in the top_boundary range of the queue
  LOOP
    BEGIN
        SELECT id INTO reserved_message_id
          FROM messages
         WHERE queue_id = queue.id
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
      UPDATE messages
         SET reserved_at = (CURRENT_TIMESTAMP)
            ,reserved_by = current_setting('application_name')
       WHERE id = reserved_message_id
   RETURNING *
        INTO reserved_message;


  RETURN reserved_message;
END;
$$ LANGUAGE plpgsql;

--
-- finalize a message, this involves removing it from the message queue and inserting it into the message_history table
--
CREATE OR REPLACE FUNCTION finalize( queue text, message_id bigint, message text ) RETURNS messages_history AS $$
DECLARE
  qid             integer;
  finalized_message   RECORD;
  historical_message  messages_history%ROWTYPE;
BEGIN
  -- Get the queue id
  SELECT id INTO qid FROM queues WHERE name = queue;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Unable to fine queue "%"', queue;
  END IF;

  DELETE FROM messages
        WHERE id = message_id
          AND reserved_at IS NOT NULL
    RETURNING * INTO finalized_message;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Unable to find message "%" in queue "%" that was reserved', message_id, queue;
  END IF;

  INSERT INTO messages_history(id    , queue_id, payload              , ready_at              , reserved_at              , reserved_by              , finalized_message)
       VALUES             (message_id, qid     , finalized_message.payload, finalized_message.ready_at, finalized_message.reserved_at, finalized_message.reserved_by, message )
    RETURNING *
         INTO historical_message;
  RETURN historical_message;
END;
$$ LANGUAGE plpgsql;

