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
    INSERT INTO stats(queue_id, name) VALUES (new_row.id, 'ready_count');
    INSERT INTO stats(queue_id, name) VALUES (new_row.id, 'reserved_count');
    INSERT INTO stats(queue_id, name) VALUES (new_row.id, 'finalized_count');
    INSERT INTO stats(queue_id, name) VALUES (new_row.id, 'producer_count');
    INSERT INTO stats(queue_id, name) VALUES (new_row.id, 'consumer_count');
  END IF;
  RETURN new_row;
END;
$$ LANGUAGE plpgsql;
SELECT * FROM use_queue('default');

--
-- Increment or decrement a stat for a queue
--
CREATE OR REPLACE FUNCTION adjust_stat( qid integer, sname text, amount integer ) RETURNS integer AS $$
DECLARE
  new_stat  integer;
BEGIN
  UPDATE stats
     SET value = value + amount
   WHERE queue_id = qid
     AND name = sname
  RETURNING value
    INTO new_stat;

  RETURN new_stat;
END;
$$ LANGUAGE plpgsql;

--
-- update the producer/consumer_count values in the stats table for all the
-- queues.
--
CREATE OR REPLACE FUNCTION update_participant_counts() RETURNS SETOF stats AS $$
DECLARE
  qrole RECORD;
  count integer;
  stat  stats%ROWTYPE;
BEGIN
  FOR qrole IN   WITH roles(role_name) AS (VALUES ('consumer'),('producer'))
               SELECT q.id        AS id
                     ,q.name      AS qname
                     ,r.role_name AS rname
                 FROM queues      AS q
           CROSS JOIN roles       AS r

  LOOP
      SELECT count(*) INTO count
        FROM pg_stat_activity
       WHERE application_name LIKE qrole.rname || '-' || qrole.qname || '-%';

      UPDATE stats
         SET value = count
       WHERE queue_id = qrole.id
         AND name = qrole.rname || '_count'
   RETURNING * INTO stat ;

      RETURN NEXT stat;
  END LOOP;
  RETURN;
END;
$$ LANGUAGE plpgsql;

--
-- Return the number of rows in the messages table for the given queue.
--
CREATE OR REPLACE FUNCTION queue_size( qname text ) RETURNS integer AS $$
DECLARE
  q_size integer;
  queue  queues%ROWTYPE;
BEGIN
  queue = use_queue( qname );

  SELECT sum(value) INTO q_size
    FROM stats
   WHERE queue_id = queue.id
     AND name IN ('ready_count', 'reserved_count')
  ;

  RETURN q_size;
END;
$$ LANGUAGE plpgsql;

--
-- Return the number of rows in the messages table for the given queue that are
-- ready, which means that their reserved_at timestamp is null.
--
CREATE OR REPLACE FUNCTION queue_ready_size( qname text ) RETURNS integer AS $$
DECLARE
  q_size integer;
  queue  queues%ROWTYPE;
BEGIN
  queue = use_queue( qname );

  SELECT value INTO q_size
    FROM stats
   WHERE queue_id = queue.id
     AND name = 'ready_count'
  ;

  RETURN q_size;
END;
$$ LANGUAGE plpgsql;

--
-- Return the number of rows in the messages table for the given queue that are
-- reserved, which means that their reserved_at timestamp is not null.
--
CREATE OR REPLACE FUNCTION queue_reserved_size( qname text ) RETURNS integer AS $$
DECLARE
  q_size integer;
  queue  queues%ROWTYPE;
BEGIN
  queue = use_queue( qname );

  SELECT value INTO q_size
    FROM stats
   WHERE queue_id = queue.id
     AND name = 'reserved_count'
  ;

  RETURN q_size;
END;
$$ LANGUAGE plpgsql;

--
-- Return the number of rows in the messages_history table for the given queue
--
CREATE OR REPLACE FUNCTION queue_finalized_size( qname text ) RETURNS integer AS $$
DECLARE
  q_size integer;
  queue  queues%ROWTYPE;
BEGIN
  queue = use_queue( qname );

  SELECT value INTO q_size
    FROM stats
   WHERE queue_id = queue.id
     AND name = 'finalized_count'
  ;

  RETURN q_size;
END;
$$ LANGUAGE plpgsql;

--
-- Count the number of consumers that are connected to the queue
--
CREATE OR REPLACE FUNCTION consumer_count( qname text ) RETURNS integer AS $$
DECLARE
  count integer;
  queue queues%ROWTYPE;
BEGIN
  queue = use_queue( qname );

  SELECT value INTO count
    FROM stats
   WHERE queue_id = queue.id
     AND name = 'consumer_count';

  RETURN count;
END;
$$ LANGUAGE plpgsql;

--
-- Count the numbero of producers that are connected to the queue
--
CREATE OR REPLACE FUNCTION producer_count( queue text )RETURNS integer AS $$
DECLARE
  count integer;
  queue queues%ROWTYPE;
BEGIN
  queue = use_queue( qname );

  SELECT value INTO count
    FROM stats
   WHERE queue_id = queue.id
     AND name = 'producer_count';

  RETURN count;
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
CREATE OR REPLACE FUNCTION put( qname text, message text ) RETURNS messages AS $$
DECLARE
  new_message messages%ROWTYPE;
  queue       queues%ROWTYPE;
BEGIN
  queue = use_queue( qname );
  INSERT INTO messages(queue_id, payload) VALUES(queue.id, message) RETURNING * INTO new_message;
  PERFORM adjust_stat( queue.id, 'ready_count', 1 );
  PERFORM pg_notify( qname, new_message.id::text );
  RETURN new_message;
END;
$$ LANGUAGE plpgsql;

--
-- reserve a message off the queue, this means updating a few fields
--
CREATE OR REPLACE FUNCTION reserve( qname text ) RETURNS SETOF messages ROWS 1 AS $$
DECLARE
  reserved_message_id integer;
  relative_top        integer;
  message_count       integer;
  consumer_count      integer;
  queue               queues%ROWTYPE;
  reserved_message    messages%ROWTYPE;
BEGIN
  -- Get the queue id
  queue          = use_queue( qname );
  consumer_count = consumer_count( qname );
  message_count  = queue_ready_size( qname );

  SELECT TRUNC( random() * consumer_count + 1 ) INTO relative_top;
  IF (consumer_count = 0) OR (message_count <= consumer_count) THEN
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
    PERFORM adjust_stat( queue.id, 'ready_count'   , -1 );
    PERFORM adjust_stat( queue.id, 'reserved_count', 1  );
  END IF;

  RETURN;

END;
$$ LANGUAGE plpgsql;

--
-- finalize a message, this involves removing it from the message queue and inserting it into the message_history table
--
CREATE OR REPLACE FUNCTION finalize( qname text, message_id bigint, note text ) RETURNS SETOF messages_history ROWS 1 AS $$
DECLARE
  historical_message  messages_history%ROWTYPE;
  queue               queues%ROWTYPE;
BEGIN
  queue = use_queue( qname );

  INSERT INTO messages_history(
                id
               ,queue_id
               ,payload
               ,ready_at
               ,reserved_at
               ,reserved_by
               ,reserved_ip
               ,finalized_note
            )
        SELECT message_id
              ,queue.id
              ,m.payload
              ,m.ready_at
              ,m.reserved_at
              ,m.reserved_by
              ,m.reserved_ip
              ,note
          FROM messages m
         WHERE id = message_id
           AND reserved_at IS NOT NULL
    RETURNING * INTO historical_message
  ;

  IF FOUND THEN
    DELETE FROM messages WHERE id = message_id;
    PERFORM adjust_stat( historical_message.queue_id, 'reserved_count' , -1 );
    PERFORM adjust_stat( historical_message.queue_id, 'finalized_count', 1  );
    RETURN next historical_message;
  ELSE
    RAISE EXCEPTION 'Unable to find reserved message "%" in queue "%".', message_id, qname;
  END IF;

  RETURN;
END;
$$ LANGUAGE plpgsql;

