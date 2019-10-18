DO $$ BEGIN

CREATE TABLE queue_classic_jobs (
  id bigserial PRIMARY KEY,
  q_name text NOT NULL CHECK (length(q_name) > 0),
  method text NOT NULL CHECK (length(method) > 0),
  args   jsonb NOT NULL,
  locked_at timestamptz,
  locked_by integer,
  created_at timestamptz DEFAULT now(),
  scheduled_at timestamptz DEFAULT now()
);

END $$ LANGUAGE plpgsql;

CREATE INDEX idx_qc_on_name_only_unlocked ON queue_classic_jobs (q_name, id) WHERE locked_at IS NULL;
CREATE INDEX idx_qc_on_scheduled_at_only_unlocked ON queue_classic_jobs (scheduled_at, id) WHERE locked_at IS NULL;
