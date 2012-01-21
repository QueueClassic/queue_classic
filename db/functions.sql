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
-- Return the number of rows in the messages table for the given queue that are
-- ready, which means that their reserved_at timestamp is null.
--
CREATE OR REPLACE FUNCTION queue_ready_size( queue text ) RETURNS integer AS $$
DECLARE
  q_size integer;
BEGIN
  SELECT count(j.id) INTO q_size
    FROM messages j
    JOIN queues q
      ON q.id = j.queue_id
   WHERE q.name = queue
     AND reserved_at IS NULL
  ;

  RETURN q_size;
END;
$$ LANGUAGE plpgsql;

--
-- Return the number of rows in the messages table for the given queue that are
-- reserved, which means that their reserved_at timestamp is not null.
--
CREATE OR REPLACE FUNCTION queue_reserved_size( queue text ) RETURNS integer AS $$
DECLARE
  q_size integer;
BEGIN
  SELECT count(j.id) INTO q_size
    FROM messages j
    JOIN queues q
      ON q.id = j.queue_id
   WHERE q.name = queue
     AND reserved_at IS NOT NULL
  ;

  RETURN q_size;
END;
$$ LANGUAGE plpgsql;

--
-- Return the number of rows in the messages_history table for the given queue
--
CREATE OR REPLACE FUNCTION queue_finalized_size( queue text ) RETURNS integer AS $$
DECLARE
  q_size integer;
BEGIN
  SELECT count(j.id) INTO q_size
    FROM messages_history j
    JOIN queues q
      ON q.id = j.queue_id
   WHERE q.name = queue
  ;

  RETURN q_size;
END;
$$ LANGUAGE plpgsql;


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
  PERFORM pg_notify( queue, new_message.id::text );
  RETURN new_message;
END;
$$ LANGUAGE plpgsql;

--
-- reserve a message off the queue, this means updating a few fields
--
CREATE OR REPLACE FUNCTION reserve( qname text ) RETURNS SETOF messages AS $$
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

  IF FOUND THEN
    -- update the reserved row
        UPDATE messages
           SET reserved_at = (CURRENT_TIMESTAMP)
              ,reserved_by = current_setting('application_name')
              ,reserved_ip = COALESCE(inet_client_addr(), '127.0.0.1'::inet)
         WHERE id = reserved_message_id
     RETURNING *
          INTO reserved_message;
    RETURN next reserved_message;
  END IF;
  RETURN;

END;
$$ LANGUAGE plpgsql;

--
-- finalize a message, this involves removing it from the message queue and inserting it into the message_history table
--
CREATE OR REPLACE FUNCTION finalize( qname text, message_id bigint, note text ) RETURNS messages_history AS $$
DECLARE
  finalized_message   RECORD;
  historical_message  messages_history%ROWTYPE;
BEGIN
  DELETE FROM messages
        WHERE id = message_id
          AND reserved_at IS NOT NULL
    RETURNING * INTO finalized_message;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Unable to find message "%" in queue "%" that was reserved', message_id, qname;
  END IF;

  INSERT INTO messages_history(
                id
               ,queue_id
               ,payload
               ,ready_at
               ,reserved_at
               ,reserved_by
               ,reserved_ip
               ,finalized_note)
       VALUES (message_id
              ,finalized_message.queue_id
              ,finalized_message.payload
              ,finalized_message.ready_at
              ,finalized_message.reserved_at
              ,finalized_message.reserved_by
              ,finalized_message.reserved_ip
              ,note )
    RETURNING *
         INTO historical_message;
  RETURN historical_message;
END;
$$ LANGUAGE plpgsql;

