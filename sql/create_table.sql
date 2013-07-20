do $$ begin

CREATE TABLE queue_classic_jobs (
  id bigserial PRIMARY KEY,
  q_name text not null check (length(q_name) > 0),
  method text not null check (length(method) > 0),
  args   text not null,
  locked_at timestamptz,
  locked_by bigserial 
);

CREATE TABLE queue_classic_workers (
    id bigserial PRIMARY KEY,
    q_name character varying(255),
    host character varying(255) NOT NULL,
    pid integer NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    last_seen timestamp without time zone DEFAULT now() NOT NULL
);

-- If json type is available, use it for the args column.
perform * from pg_type where typname = 'json';
if found then
  alter table queue_classic_jobs alter column args type json using (args::json);
end if;

end $$ language plpgsql;

create function queue_classic_notify() returns trigger as $$ begin
  perform pg_notify(new.q_name, '');
  return null;
end $$ language plpgsql;

create trigger queue_classic_notify
after insert on queue_classic_jobs
for each row
execute procedure queue_classic_notify();

CREATE INDEX idx_qc_on_name_only_unlocked ON queue_classic_jobs (q_name, id) WHERE locked_at IS NULL;
CREATE INDEX idx_qc_on_locked_by ON queue_classic_jobs USING btree (q_name, id) 

