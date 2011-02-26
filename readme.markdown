# Queue Classic
__Beta 0.2.2__

__Queue Classic 0.2.2 is in Beta.__ I have been using this library with 30-50 Heroku workers and have had great results.

I am using this in production applications and plan to maintain and support this library for a long time.

Queue Classic is an alternative queueing library for Ruby apps (Rails, Sinatra, Etc...) Queue Classic features a blocking dequeue, database maintained locks and
no ridiculous dependencies. As a matter of fact, Queue Classic only requires the __pg__ and __json__.

## Installation

### TL;DR
1. gem install queue_classic
2. add jobs table to your database
3. QC.enqueue "Class.method", :arg1 => val1
4. rake qc:work

### Dependencies

  Postgres version 9

  Ruby (gems: pg, json)

### Gem

    gem install queue_classic

### Database

Queue Classic needs a database, so make sure that DATABASE_URL points to your database. If you are unsure about whether this var is set, run:
    echo $DATABASE_URL
in your shell. If you are using Heroku, this var is set and pointing to your primary database.

Once your Database is set, you will need to add a jobs table. If you are using rails, add a migration with the following tables:

    class CreateJobsTable < ActiveRecord::Migration
      def self.up
        create_table :jobs do |t|
          t.text :details
          t.timestamp :locked_at
          t.index :id
        end
      end

      def self.down
        drop_table :jobs
      end
    end
After running this migration, your database should be ready to go. As a sanity check, enqueue a job and then issue a SELECT in the postgres console.

Be sure and add the index to the id column. This will help out the worker if the queue should ever reach an obscene length. It made a huge difference
when running the benchmark.

__script/console__
    QC.enqueue "Class.method"
__Terminal__
    psql you_database_name
    select * from jobs;
You should see the job "Class.method"

### Rakefile

As a convenience, I added a rake task that responds to `rake jobs:work` There are also rake tasks in the `qc` name space.
To get access to these tasks, Add `require 'queue_classic/tasks'` to your Rakefile.

## Fundamentals

### Enqueue

To place a job onto the queue, you should specify a class and a class method. There are a few ways to enqueue:

    QC.enqueue('Class.method', :arg1 => 'value1', :arg2 => 'value2')

Requires:

    class Class
      def self.method(args)
        puts args["arg1"]
      end
    end

    QC.enqueue('Class.method', 'value1', 'value2')

Requires:

    class Class
      def self.method(arg1,arg2)
        puts arg1
        puts arg2
      end
    end


The job gets stored in the jobs table with a details field set to: `{ job: Class.method, params: {arg1: value1, arg2: value2}}` (as JSON)
Here is a more concrete example of a job implementation using a Rails ActiveRecord Model:

    class Invoice < ActiveRecord::Base
      def self.process(invoice_id)
        invoice = find(invoice_id)
        invoice.process!
      end

      def self.process_all
        Invoice.all do |invoice|
          QC.enqueue "Invoice.process", invoice.id
        end
      end
    end


### Dequeue

Traditionally, a queue's dequeue operation will remove the item from the queue. However, Queue Classic will not delete the item from the queue right away; instead, the workers will lock
the job and then the worker will delete the job once it has finished working it. Queue Classic's greatest strength is it's ability to safely lock jobs. Unlike other
database backed queing libraries, Queue Classic uses the database time to lock. This allows you to be more relaxed about the time synchronization amongst your worker machines.

Queue Classic takes advantage of Postgres' PUB/SUB featuers to dequeue a job. Basically there is a channel in which the workers LISTEN. When a new job is added to the queue, the queue sends NOTIFY
messages on the channel. Once a NOTIFY is sent, each worker races to acquire a lock on a job. A job is awareded to the victor while the rest go back to wait for another job. This eliminates
the need to Sleep & Select.

### The Worker

The worker calls dequeue and then calls the enqueued method with the supplied arguments. Once the method terminates, the job is deleted from the queue. In the case that your method
does not terminate, or the worker unexpectingly dies, Queue Classic will do following:

* Rescue the Exception %
* Call handle_failure(job,exception)
* Delete the job

% - To my knowledge, the only thing that can usurp ensure is a segfault.

By default, handle_failure will puts the job and the exception. This is not very good and you should override this method. It is simple to do so.
If you are using Queue Classic with Rails, You should:

1. Remove require 'queue_classic/tasks' from Rakefile
2. Create new file in lib/tasks. Call it queue_classic.rb (name is arbitrary)
3. Insert something like the following:

#### lib/tasks/queue_classic.rb

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
        QC.enqueue(job)

      end
    end

    namespace :jobs do
      task :work  => :environment do
        MyWorker.new.start
      end
    end

## Performance
I am pleased at the performance of Queue Classic. It ran 3x faster than the DJ. (I have yet to benchmark redis backed queues)

    ruby benchmark.rb
                    user     system      total        real
                0.950000   0.620000   1.570000 (  9.479941)

Hardware: Mac Book Pro 2.8 GHz Intel Core i7. SSD. 4 GB memory.

Software: Ruby 1.9.2-p0, PostgreSQL 9.0.2

It is fast because:

* I wrote my own SQL
* I do not create many Ruby Objects
* I do not call very many methods

## FAQ

How is this different than DJ?
> TL;DR = Store job as JSON (better introspection), Queue manages the time for locking jobs (workers can be out of sync.), No magic (less code), Small footprint (ORM Free).

> __Introspection__ I want the data in the queue to be as simple as possible. Since we only store the Class, Method and Args, introspection into the queue is
quite simple.

> __Locking__ You might have noticed that DJ's worker calls Time.now(). In a cloud environment, this could allow for workers to be confused about
the status of a job. Classic Queue locks a job using Postgres' TIMESTAMP function.

> __Magic__ I find disdain for methods on my objects that have nothing to do with the purpose of the object. Methods like "should" and "delay"
are quite distasteful and obscure what is actually going on. If you use TestUnit for this reason, you might like Queue Classic. Anyway, I think
the fundamental concept of a message queue is not that difficult to grasp; therefore, I have taken the time to make Queue Classic as transparent as possilbe.

> __Footprint__ You don't need ActiveRecord or any other ORM to find the head or add to the tail. Take a look at the DurableArray class to see the SQL Classic Queue employees.

Why doesn't your queue retry failed jobs?
> I believe the Class method should handle any sort of exception.  Also, I think
that the model you are working on should know about it's state. For instance, if you are
creating jobs for the emailing of newsletters; put a emailed_at column on your newsletter model
and then right before the job quits, touch the emailed_at column. That being said, you can do whatever you
want in handle_failure. I will not decide what is best for your application.

Can I use this library with 50 Heroku Workers?
> Yes.

Is Queue Classic ready for production? Can I do it live?!?
> I started this project on 1/24/2011. I have been using this in production for some high-traffic apps at Heroku since 2/24/2011.
