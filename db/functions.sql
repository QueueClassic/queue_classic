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
SELECT * FROM use_queue('classic');

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
-- The procedure to fire on insert, update, delete's from to the messages table
--
CREATE OR REPLACE FUNCTION stats_ready_reserved_counts() RETURNS trigger AS $$
BEGIN
  CASE TG_OP
  WHEN 'INSERT' THEN
    IF NEW.reserved_at IS NULL THEN
      PERFORM adjust_stat( NEW.queue_id, 'ready_count', 1 );
    ELSE
      PERFORM adjust_stat( NEW.queue_id, 'reserved_count', 1 );
    END IF;
    RETURN NEW;

  WHEN 'UPDATE' THEN
    IF OLD.reserved_at IS NULL THEN
      IF NEW.reserved_at IS NOT NULL THEN
        PERFORM adjust_stat( NEW.queue_id, 'reserved_count', 1 );
        PERFORM adjust_stat( OLD.queue_id, 'ready_count', -1 );
      END IF;
    END IF;
    RETURN NEW;

  WHEN 'DELETE' THEN
    IF OLD.reserved_at IS NOT NULL THEN
      PERFORM adjust_stat( OLD.queue_id, 'reserved_count', -1 );
    ELSE
      PERFORM adjust_stat( OLD.queue_id, 'ready_count', -1 );
    END IF;
    RETURN OLD;
  END CASE;
END;
$$ LANGUAGE plpgsql;

--
-- Adjust ready_count or reserved_count on insert into messages
--
DROP TRIGGER IF EXISTS messages_triggger ON messages;
CREATE TRIGGER messages_trigger AFTER INSERT OR UPDATE OR DELETE ON messages
  FOR EACH ROW EXECUTE PROCEDURE stats_ready_reserved_counts();


--
-- The procedure to fine on insert or delete from messages_history table
--
CREATE OR REPLACE FUNCTION stats_finalized_counts() RETURNS trigger AS $$
BEGIN
  CASE TG_OP
  WHEN 'INSERT' THEN
    PERFORM adjust_stat( NEW.queue_id, 'finalized_count', 1 );

  WHEN 'DELETE' THEN
    PERFORM adjust_stat( OLD.queue_id, 'finalized_count', -1 );
  END CASE;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

--
-- Adjust finalized_count on messages_history;
--
DROP TRIGGER IF EXISTS messages_history_triggger ON messages_history;
CREATE TRIGGER messages_history_trigger AFTER INSERT OR DELETE ON messages_history
  FOR EACH ROW EXECUTE PROCEDURE stats_finalized_counts();


--
-- retrieve a partuclar stat for a particular queue
--
CREATE OR REPLACE FUNCTION queue_stat( qname text, sname text ) RETURNS integer AS $$
DECLARE
  queue  queues%ROWTYPE;
  retval integer;
BEGIN
  queue = use_queue( qname );

  SELECT value INTO retval
    FROM stats
   WHERE queue_id = queue.id
     AND name = sname ;

  RETURN retval;
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
  FOR qrole IN SELECT * FROM queue_roles
  LOOP
      SELECT count(*) INTO count
        FROM pg_stat_activity
       WHERE application_name LIKE qrole.role_name || '-' || qrole.queue_name || '-%';

      UPDATE stats
         SET value = count
       WHERE queue_id = qrole.queue_id
         AND name = qrole.role_name || '_count'
   RETURNING * INTO stat ;

      RETURN NEXT stat;
  END LOOP;
  RETURN;
END;
$$ LANGUAGE plpgsql;

--
-- update the ready_count stat for a queue
--
CREATE OR REPLACE FUNCTION update_ready_count( qname text ) RETURNS stats AS $$
DECLARE
  queue queues%ROWTYPE;
  stat  stats%ROWTYPE;
BEGIN
  queue = use_queue( qname );
  UPDATE stats AS s
     SET value = (SELECT count(*)
                    FROM messages
                   WHERE ready_at IS NOT NULL
                     AND reserved_at IS NULL
                     AND queue_id = queue.id )
    WHERE queue_id = queue.id
      AND name = 'ready_count'
  RETURNING * INTO stat;
  RETURN stat;
END;
$$ LANGUAGE plpgsql;

--
-- update the reserved_count stat for a queue
--
CREATE OR REPLACE FUNCTION update_reserved_count( qname text ) RETURNS stats AS $$
DECLARE
  queue queues%ROWTYPE;
  stat  stats%ROWTYPE;
BEGIN
  queue = use_queue( qname );
  UPDATE stats AS s
     SET value = (SELECT count(*)
                    FROM messages
                   WHERE ready_at IS NOT NULL
                     AND reserved_at IS NOT NULL
                     AND queue_id = queue.id )
    WHERE queue_id = queue.id
      AND name = 'reserved_count'
  RETURNING * INTO stat;
  RETURN stat;
END;
$$ LANGUAGE plpgsql;

--
-- update the finalized_count stat for a queue
--
CREATE OR REPLACE FUNCTION update_finalized_count( qname text ) RETURNS stats AS $$
DECLARE
  queue queues%ROWTYPE;
  stat  stats%ROWTYPE;
BEGIN
  queue = use_queue( qname );
  UPDATE stats AS s
     SET value = (SELECT count(*)
                    FROM messages_history
                   WHERE queue_id = queue.id )
    WHERE queue_id = queue.id
      AND name = 'finalized_count'
  RETURNING * INTO stat;
  RETURN stat;
END;
$$ LANGUAGE plpgsql;


--
-- update the queue counts to their actual numbers
--
CREATE OR REPLACE FUNCTION update_queue_counts() RETURNS SETOF stats AS $$
DECLARE
  queue queues%ROWTYPE;
  stat  stats%ROWTYPE;
BEGIN
  FOR queue IN SELECT * FROM queues
  LOOP
    RETURN QUERY SELECT * FROM update_ready_count( queue.name );
    RETURN QUERY SELECT * FROM update_reserved_count( queue.name );
    RETURN QUERY SELECT * FROM update_finalized_count( queue.name );
  END LOOP;
  RETURN;
END;
$$ LANGUAGE plpgsql;


--
-- Return the number of rows in the messages table for the given queue.
--
CREATE OR REPLACE FUNCTION queue_processing_count( qname text ) RETURNS integer AS $$
DECLARE
  sum   integer;
  queue queues%ROWTYPE;
BEGIN
  queue = use_queue( qname );

  SELECT sum(value) INTO sum
    FROM stats
   WHERE queue_id = queue.id
     AND name IN ('ready_count', 'reserved_count')
  ;

  RETURN sum;
END;
$$ LANGUAGE plpgsql;

--
-- Return the number of rows in the messages table for the given queue that are
-- ready, which means that their reserved_at timestamp is null.
--
CREATE OR REPLACE FUNCTION queue_ready_count( qname text ) RETURNS integer AS $$
DECLARE
BEGIN
  RETURN queue_stat( qname, 'ready_count' );
END;
$$ LANGUAGE plpgsql;

--
-- Return the number of rows in the messages table for the given queue that are
-- reserved, which means that their reserved_at timestamp is not null.
--
CREATE OR REPLACE FUNCTION queue_reserved_count( qname text ) RETURNS integer AS $$
DECLARE
BEGIN
  RETURN queue_stat( qname, 'reserved_count' );
END;
$$ LANGUAGE plpgsql;

--
-- Return the number of rows in the messages_history table for the given queue
--
CREATE OR REPLACE FUNCTION queue_finalized_count( qname text ) RETURNS integer AS $$
DECLARE
BEGIN
  RETURN queue_stat( qname, 'finalized_count' );
END;
$$ LANGUAGE plpgsql;

--
-- Count the number of consumers that are connected to the queue
--
CREATE OR REPLACE FUNCTION consumer_count( qname text ) RETURNS integer AS $$
DECLARE
BEGIN
  RETURN queue_stat( qname, 'consumer_count' );
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
  RETURN queue_stat( qname, 'producer_count' );
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
  message_count  = queue_ready_count( qname );

  SELECT TRUNC( random() * consumer_count + 1 ) INTO relative_top;
  IF (consumer_count = 0) OR (message_count <= consumer_count) THEN
    relative_top = 0;
  END IF;

  -- select for update a random message in the relative_top range of the queue
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
-- reset_orphan_messages, this will take those messages that are currently
-- reserved, but whose app is no longer listed and reset their reserved_* fields
-- so the message is ready again for processing
--
CREATE OR REPLACE FUNCTION reset_orphaned_messages() RETURNS SETOF messages AS $$
DECLARE
  found_msg   messages%ROWTYPE;
  updated_msg messages%ROWTYPE;
BEGIN
  FOR found_msg IN SELECT * FROM messages WHERE reserved_at IS NOT NULL
  LOOP
     PERFORM application_name
        FROM pg_stat_activity
       WHERE application_name = found_msg.reserved_by;

    IF NOT FOUND THEN
          UPDATE messages
             SET reserved_at = NULL
                ,reserved_by = NULL
                ,reserved_ip = NULL
                ,ready_at    = (CURRENT_TIMESTAMP)
           WHERE id = found_msg.id
       RETURNING * INTO updated_msg;

      RETURN NEXT updated_msg;
    END IF;
  END LOOP;
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
    RETURN next historical_message;
  ELSE
    RAISE EXCEPTION 'Unable to find reserved message "%" in queue "%".', message_id, qname;
  END IF;

  RETURN;
END;
$$ LANGUAGE plpgsql;

