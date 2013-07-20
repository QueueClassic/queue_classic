DROP FUNCTION IF EXISTS lock_head(tname varchar);
DROP FUNCTION IF EXISTS lock_head(q_name varchar, top_boundary integer);
DROP FUNCTION IF EXISTS lock_head(tname varchar, worker_id bigint, worker_update_time int);
DROP FUNCTION IF EXISTS lock_head(tname varchar, top_boundary integer, worker_id bigint, worker_update_time int);
DROP FUNCTION IF EXISTS queue_classic_notify() cascade;
