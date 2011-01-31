# Queue Classic
__Alpha 0.1.5__

_Queue Classic 0.1.5 is not ready for production. However, it is under active development and I expect a beta release within the following months._

Queue Classic is an alternative queueing library for Ruby apps (Rails, Sinatra, Etc...) Queue Classic features __asynchronous__ job polling, database maintained locks and
no ridiculous dependencies. As a matter of fact, Queue Classic only requires the __pg__ and __json__.

## Installation

### TL;DR
1. gem install queue_classic
2. add jobs table to your database
3. QC.enqueue "Class.method", :arg1 => val1
4. rake qc:work

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
        end
      end

      def self.down
        drop_table :jobs
      end
    end
After running this migration, your database should be ready to go. As a sanity check, enqueue a job and then issue a SELECT in the postgres console.

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

To place a job onto the queue, you should specify a class and a class method. The syntax should be:

    QC.enqueue('Class.method', :arg1 => 'value1', :arg2 => 'value2')

The job gets stored in the jobs table with a details field set to: `{ job: Class.method, params: {arg1: value1, arg2: value2}}` (as JSON)
Class can be any class and method can be anything that Class will respond to. For example:

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

Traditionally, a queue's dequeue operation will remove the item from the queue. However, Queue Classic will not delete the item from the queue, it will lock it
and then the worker will delete the job once it has finished working it. Queue Classic's greatest strength is it's ability to safely lock jobs. Unlike other
database backed queing libraries, Classic Queue uses the database time to lock. This allows you to be more relaxed about the time synchronization of your worker machines.

Finally, the strongest feature of Queue Classic is it's ability to block on on dequeue. This design removes the need to __ Sleep & SELECT. __ Queue Classic takes advantage
of the wonderul PUB/SUB featuers built in to Postgres. Basically there is a channel in which the workers LISTEN. When a new job is added to the queue, the queue sends NOTIFY
messages on the channel. Once a NOTIFY is sent, each worker races to acquire a lock on a job. A job is awareded to the victor while the rest go back to wait for another job.

## FAQ

How is this different than DJ?
> TL;DR = Store job as JSON (better introspection), Queue manages the time for locking jobs (workers can be out of sync.), No magic (less code), Small footprint (ORM Free).

> __Introspection__ I want the data in the queue to be as simple as possible. Since we only store the Class, Method and Args, introspection into the queue is
quite simpler.

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
and then right before the job quits, touch the emailed_at column.

Can I use this library with 50 Heroku Workers?
> Maybe. I haven't tested 50 workers yet. But it is definitely a goal for Queue Classic. I am not sure when,
but you can count on this library being able to handle all Heroku can throw at it.

Why does this project seem incomplete? Will you make it production ready?
> I started this project on 1/24/2011. Check back soon! Also, feel free to contact me to find out how passionate I am about queueing.
