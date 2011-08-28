### Single Queue

You should already have created a table named queue_classic_jobs. This is the default queue.
You can use the queueing methods on the QC module to interact with the default queue.

```ruby

  QC.enqueue("Class.method","arg1","arg2")
  QC.dequeue
  QC.length
  QC.query("Class.method")
  QC.delete_all

```

It should be noted that the following enqueue calls do the same thing.

```ruby
  QC.enqueue("Class.method")
  QC::Queue.enqueue("Class.method")
  QC::Queue.new("queue_classic_jobs").enqueue("Class.method")
```

### Multiple Queues

If you want to create a new queue, you will need to create a new table. The
table should look identical to the queue_classic_jobs table.

```bash
  $ psql your_database
  your_database=# CREATE TABLE priority_jobs (id serial, details text, locked_at timestamp);
  your_database=# CREATE INDEX priority_jobs_id_idx ON priority_jobs (id);
  your_database=# \q
  $
```

Once you create a table named "priority_jobs", you will need to create an
instance of QC::Queue and tell it to attach to your newly created table.

```ruby
  @queue = QC::Queue.new("priority_jobs")
  @queue.enqueue("Class.method", "arg1")
```

Any method available to the default queue (i.e. QC.enqueue)
is available to @queue. In fact, both the class and instances
of the class get their queueing methods from the same module, the AbstractQueue module.
Look it up in lib/queue_classic/queue.rb for the particulars.

Now, just instruct your worker to attach to your newly created queue.

```bash
  rake jobs:work QUEUE="priority_jobs"
```

For more information regarding the Worker, see the worker page in the docs
directory.
