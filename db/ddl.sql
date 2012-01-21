DROP TABLE IF EXISTS queues CASCADE;
CREATE TABLE queues(
  id            serial UNIQUE PRIMARY KEY,
  name          text   UNIQUE
);
INSERT INTO queues(name) VALUES ('default');

DROP TABLE IF EXISTS jobs CASCADE;
CREATE TABLE jobs (
  id              bigserial UNIQUE PRIMARY KEY,
  queue_id        integer   REFERENCES queues(id),
  payload         text      NOT NULL,
  ready_at        timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  reserved_at     timestamp,
  reserved_app    text, -- application_name
  reserved_ip     inet, -- inet_client_addr()
  reserved_port   int   -- inet_client_port()
);

DROP TABLE IF EXISTS jobs_history CASCADE;
CREATE TABLE jobs_history (
  id                bigint    UNIQUE PRIMARY KEY,
  queue_id          integer   REFERENCES queues(id),
  details           text      NOT NULL,
  ready_at          timestamp NOT NULL,
  reserved_at       timestamp NOT NULL,
  reserved_app      text      NOT NULL,
  reserved_ip       inet      NOT NULL,
  reserved_port     int       NOT NULL,
  finalized_at      timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  finalized_message text
);

CREATE SEQUENCE application_id_seq
  INCREMENT BY 1
  MINVALUE 1
  NO MAXVALUE
  NO CYCLE
  OWNED BY jobs.reserved_app
  ;
