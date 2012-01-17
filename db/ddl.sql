-- Before running this ddl
-- 1) Create the database these tables should go in
-- 2) Create a 'queue_classic' schema other schema that should hold these
-- tables.
--

-- Fill out the next line appropriately and uncomment it. The first item after
-- the TO should be the schema created above in (2).
-- SET search_path TO queue_classic,public;

DROP TABLE IF EXISTS queues CASCADE;
CREATE TABLE queues(
  id            serial UNIQUE PRIMARY KEY,
  name          text   UNIQUE
);

DROP TABLE IF EXISTS jobs CASCADE;
CREATE TABLE jobs (
  id              bigserial UNIQUE PRIMARY KEY,
  queue_id        integer   REFERENCES queues(id),
  details         text      NOT NULL,
  ready_at        timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  reserved_at     timestamp,
  reserved_by     text
);

DROP TABLE IF EXISTS jobs_history CASCADE;
CREATE TABLE jobs_history (
  id                bigint    UNIQUE PRIMARY KEY,
  queue_id          integer   REFERENCES queues(id),
  details           text      NOT NULL,
  ready_at          timestamp NOT NULL,
  reserved_at       timestamp NOT NULL,
  reserved_by       text      NOT NULL,
  finalized_at      timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  finalized_message text
);


