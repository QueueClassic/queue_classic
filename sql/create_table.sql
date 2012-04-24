CREATE TABLE queue_classic_jobs (
  id serial PRIMARY KEY,
  q_name varchar(255),
  method varchar(255),
  args text,
  locked_at timestamptz
);

CREATE INDEX idx_qc_on_name_only_unlocked ON queue_classic_jobs (q_name, id) WHERE locked_at IS NULL;
