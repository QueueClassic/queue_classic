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


The worker is an instance of the QC::Worker class.
The worker will begin working when you call __start()__ on the worker object.
__start()__ will dequeue and work until you kill the process.
If the job raises an exception, Queue Classic will ensure that handle_failure(job,exception) gets called.
You may want to subclass queue_classic's worker to define your own failure strategy.

By default, handle_failure will print the job and the exception.
Of course, you can override this behavior. In Rails you can do the following:

1. Remove require 'queue_classic/tasks' from Rakefile
2. Create new file in lib/tasks. Call it queue_classic.rb
3. Insert something the following

```ruby

    require 'queue_classic'
    class MyWorker < QC::Worker

      def handle_failure(job,exception)
        # You can do many things inside of this method. Here are a few examples:

        # Log to Exceptional
        Exceptional.handle(exception, "Background Job Failed" + job.inspect)

        # Log to Hoptoad
        HoptoadNotifier.notify(
            :error_class   => "Background Job",
            :error_message => "Special Error: #{e.message}",
            :parameters    => job.details
        )

        # Log to STDOUT (Heroku Logplex listens to stdout)
        puts job.inspect
        puts exception.inspect
        puts exception.backtrace

        # Retry the job
        @queue.enqueue(job)

      end
    end

    namespace :jobs do
      task :work  => :environment do
        MyWorker.new.start
      end
    end

```

**Un-handled Exceptions**

The worker calls dequeue and then calls the enqueued method with the supplied arguments.
Once the method terminates, the job is deleted from the queue. In the case that your method
does not terminate, or the worker expectingly dies, Queue Classic will do following:

* Rescue the Exception using Ruby's __ensure__ block %
* Call handle_failure(job,exception)
* Delete the job

% - To my knowledge, the only thing that can usurp ensure is a segfault.

**Stopping a worker**

    If the worker is in the middle of working a job:
      ^C => Kill the worker after job is finished.
      ^C^C => Kill the worker immediately.
    If the worker is idle
      ^C => Kills the worker.
