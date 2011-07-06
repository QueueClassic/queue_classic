# queue_classic performance

If you look in lib/queue_classic/database.rb you will find the PL/pgSQL function
lock_head(). This function is responsible for selecting and locking jobs for the
worker. In this function you will see that it does a trick to set the offset. It
finds the size of the table and then determines if it should use a random
offset. At first I wondered if this would be a performance problem, but in
practice I have not found any such problems. In fact:

On a table with 1,000,000 rows and an index on the ID column, I see the following:

*enqueue*

```sql

  queue_classic_test=# EXPLAIN ANALYZE INSERT INTO queue_classic_jobs (details) VALUES ('test');

  QUERY PLAN
  ------------------------------------------------------------------------------------------
  Insert  (cost=0.00..0.01 rows=1 width=0) (actual time=0.092..0.092 rows=0 loops=1)
  ->  Result  (cost=0.00..0.01 rows=1 width=0) (actual time=0.029..0.030 rows=1 loops=1)
  Total runtime: 0.174 ms

```

*dequeue*

```sql

  queue_classic_test=# EXPLAIN ANALYZE select * from lock_head('queue_classic_jobs');

  QUERY PLAN
  -------------------------------------------------------------------------------------------------------------
  Function Scan on lock_head (cost=0.25..10.25 rows=1000 width=44) (actual time=0.824..0.824 rows=1 loops=1)
  Total runtime: 0.842 ms

```

Under the hood, the lock_head function does this:

```sql

queue_classic_test=# EXPLAIN ANALYZE select id from queue_classic_jobs where locked_at IS NULL limit 1 offset 0 for update nowait;

QUERY PLAN
-----------------------------------------------------------------------------------------------------------------------------------
Limit (cost=0.00..0.03 rows=1 width=10) (actual time=0.164..0.165 rows=1 loops=1)
  ->  LockRows (cost=0.00..29640.02 rows=1010001 width=10) (actual time=0.163..0.163 rows=1 loops=1)
    ->  Seq Scan on queue_classic_jobs (cost=0.00..19540.01 rows=1010001 width=10) (actual time=0.149..0.149 rows=1 loops=1)
      Filter: (locked_at IS NULL)
Total runtime:
0.227ms

```
