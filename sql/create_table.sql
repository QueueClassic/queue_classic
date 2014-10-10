do $$ begin

CREATE TABLE queue_classic_jobs (
  id bigserial PRIMARY KEY,
  q_name text not null check (length(q_name) > 0),
  method text not null check (length(method) > 0),
  args   text not null,
  locked_at timestamptz,
  locked_by integer,
  created_at timestamptz default now()
);

-- If json type is available, use it for the args column.
perform * from pg_type where typname = 'json';
if found then
  alter table queue_classic_jobs alter column args type json using (args::json);
end if;

end $$ language plpgsql;

CREATE INDEX idx_qc_on_name_only_unlocked ON queue_classic_jobs (q_name, id) WHERE locked_at IS NULL;
