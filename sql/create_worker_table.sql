CREATE TABLE queue_classic_jobs (
  id serial, 
  q_name varchar(255), 
  method varchar(255), 
  args text, 
  locked_at timestamp
);
