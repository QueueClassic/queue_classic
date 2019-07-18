-- queue_classic_notify function and trigger
CREATE FUNCTION queue_classic_notify() RETURNS TRIGGER AS $$ BEGIN
  perform pg_notify(new.q_name, ''); RETURN NULL;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER queue_classic_notify
AFTER INSERT ON queue_classic_jobs FOR EACH ROW
EXECUTE PROCEDURE queue_classic_notify();
