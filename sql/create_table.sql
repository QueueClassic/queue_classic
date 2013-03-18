CREATE TABLE queue_classic_jobs (
  id bigserial PRIMARY KEY,
  q_name varchar(255),
  method varchar(255),
  args text,
  locked_at timestamptz
);

create function queue_classic_notify() returns trigger as $$ begin
  perform pg_notify(new.q_name, '');
  return null;
end $$ language plpgsql;

create trigger queue_classic_notify
after insert on queue_classic_jobs
for each row
execute procedure queue_classic_notify();

CREATE INDEX idx_qc_on_name_only_unlocked ON queue_classic_jobs (q_name, id) WHERE locked_at IS NULL;
