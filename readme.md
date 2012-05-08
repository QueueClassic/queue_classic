# queue_classic

v2.0.0

queue_classic provides PostgreSQL-backed queueing focused on concurrent job
locking and minimizing database load while providing a simple, intuitive user
experience.

queue_classic features:

* Support for multiple queues with heterogeneous workers
* Utilization of Postgres' PUB/SUB
* JSON encoding
* Forking workers
* Postgres' rock-solid locking mechanism
* Fuzzy-FIFO support [academic paper](http://www.cs.tau.ac.il/~shanir/nir-pubs-web/Papers/Lock_Free.pdf)
* Instrumentation via log output
* Long term support

## Proven

queue_classic was designed out of the necessity for a fast, reliable, low
maintenance message queue.  It was built upon PostgreSQL to avoid the necessity
of adding redis or 0MQ services to my applications. It was designed to be
simple, with a small API and very few features. For a simple mechanism to
distribute jobs to worker processes, especially if you are already running
PostgreSQL, queue_classic is exactly what you should be using. If you need
more advanced queueing features, you should investigate 0MQ, rabbitmq, or redis.

### Heroku Postgres

The Heroku Postgres team uses queue_classic to monitor the health of
customer databases, processng 200 jobs per second using a [fugu](https://postgres.heroku.com/pricing)
database. They chose queue_classic because of its simplicity and reliability.

### Cloudapp

Larry uses queue_classic to deliver cloudapp's push notifications and collect
file meta-data from S3, processing nearly 14 jobs per second.

```
I haven't even touched QC since setting it up.
The best queue is the one you don't have to hand hold.

-- Larry Marburger
```

## Setup

In addition to installing the rubygem, you will need to prepare your database.
Database preparation includes creating a table and loading PL/pgSQL functions.
You can issue the database preparation commands using **PSQL(1)** or place them in a
database migration.

### Quick Start

```bash
$ gem install queue_classic
$ createdb queue_classic_test
$ export QC_DATABASE_URL="postgres://username:password@localhost/queue_classic_test"
$ ruby -r queue_classic -e "QC::Setup.create"
$ ruby -r queue_classic -e "QC.enqueue('Kernel.puts', 'hello world')"
$ ruby -r queue_classic -e "QC::Worker.new.work"
```

### Ruby on Rails Setup

**Gemfile**

```ruby
source :rubygems
gem "queue_classic", "2.0.0"
```

**Rakefile**

```ruby
require "queue_classic"
require "queue_classic/tasks"
```

**config/initializers/queue_classic.rb**

```ruby
# Optional if you have this set in your shell environment or use Heroku.
ENV["DATABASE_URL"] = "postgres://username:password@localhost/database_name"
```

queue_classic requires a database table and a PL/pgSQL function to be loaded
into your database. You can load the table and the function by running a migration
or using a rake task.

**db/migrations/add_queue_classic.rb**

```ruby
require 'queue_classic'

class AddQueueClassic < ActiveRecord::Migration

  def self.up
    QC::Setup.create
  end

  def self.down
    QC::Setup.drop
  end

end
```

**Rake Task**

```bash
# Creating the table and functions
$ bundle exec rake qc:create

# Dropping the table and functions
$ bundle exec rake qc:drop
```


### Sequel Setup

**db/migrations/1_add_queue_classic.rb**

```ruby
require 'queue_classic'

Sequel.migration do
  up {QC::Setup.create}
  down {QC::Setup.down}
end
```

## Configure

All configuration takes place in the form of environment vars.
See [queue_classic.rb](https://github.com/ryandotsmith/queue_classic/blob/master/lib/queue_classic.rb#L29-66)
for a list of options.

## Usage

Users of queue_classic will be producing jobs (enqueue) or
consuming jobs (lock then delete).

### Producer

You certainly don't need the queue_classic rubygem to put a job in the queue.

```bash
$ psql queue_classic_test -c "INSERT INTO queue_classic_jobs (q_name, method, args) VALUES ('default', 'Kernel.puts', '[\"hello world\"]');"
```

However, the rubygem will take care of converting your args to JSON and it will also dispatch
PUB/SUB notifications if the feature is enabled. It will also manage a connection to the database
that is independent of any other connection you may have in your application. Note: If your
queue table is in your application's database then your application's process will have 2 connections
to the database; one for your application and another for queue_classic.

The Ruby API for producing jobs is pretty simple:

```ruby
# This method has no arguments.
QC.enqueue("Time.now")

# This method has 1 argument.
QC.enqueue("Kernel.puts", "hello world")

# This method has 2 arguments.
QC.enqueue("Kernel.printf", "hello %s", "world")

# This method has a hash argument.
QC.enqueue("Kernel.puts", {"hello" => "world"})

# This method has an array argument.
QC.enqueue("Kernel.puts", ["hello", "world"])
```

The basic idea is that all arguments should be easily encoded to json. OkJson
is used to encode the arguments, so the arguments can be anything that OkJson can encode.

```ruby
# Won't work!
OkJson.encode({:test => "test"})

# OK
OkJson.encode({"test" => "test"})
```

To see more information on usage, take a look at the test files in the source code. Also,
read up on [OkJson](https://github.com/kr/okjson)

#### Multiple Queues

The table containing the jobs has a column named *q_name*. This column
is the abstraction queue_classic uses to represent multiple queues. This allows
the programmer to place triggers and indexes on distinct queues.

```ruby
# attach to the priority_queue. this will insert
# jobs with the column q_name = 'priority_queue'
p_queue = QC::Queue.new("priority_queue")

# This method has no arguments.
p_queue.enqueue("Time.now")

# This method has 1 argument.
p_queue.enqueue("Kernel.puts", "hello world")

# This method has 2 arguments.
p_queue.enqueue("Kernel.printf", "hello %s", "world")

# This method has a hash argument.
p_queue.enqueue("Kernel.puts", {"hello" => "world"})

# This method has an array argument.
p_queue.enqueue("Kernel.puts", ["hello", "world"])
```

This code example shows how to produce jobs into a custom queue,
to consume jobs from the custom queue be sure and set the `$QUEUE`
var to the q_name in the worker's UNIX environment.

### Consumer

There are several approaches to working jobs. The first is to include
a task file provided by queue_classic and the other approach is to
write a custom bin file.

#### Rake Task

Be sure to include `queue_classic` and `queue_classic/tasks`
in your primary Rakefile.

To work jobs from the default queue:

```bash
$ bundle exec rake qc:work
```
To work jobs from a custom queue:

```bash
$ QUEUE="p_queue" bundle exec rake qc:work
```

#### Bin File

Start by making a bin directory in your project's root directory.
Then add an executable file called worker.

**bin/worker**

```ruby
#!/usr/bin/env ruby
# encoding: utf-8

trap('INT')  {exit}
trap('TERM') {exit}

require "your_app"
require "queue_classic"
QC::Worker.new.start
```

#### Sublcass QC::Worker

Now that we have seen how to run a worker process, let's take a look at how to customize a worker.
The class `QC::Worker` will probably suit most of your needs; however, there are some mechanisms
that you will want to override. For instance, if you are using a forking worker, you will need to
open a new database connection in the child process that is doing your work. Also, you may want to
define how a failed job should behave. The default failed handler will simply print the job to stdout.
You can define a failure method that will enqueue the job again, or move it to another table, etc....

```ruby
require "queue_classic"

class MyWorker < QC::Worker

  # retry the job
  def handle_failure(job, exception)
    @queue.enqueue(job[:method], job[:args])
  end

  # the forked proc needs a new db connection
  def setup_child
    ActiveRecord::Base.establish_connection
  end

end
```

Notice that we have access to the `@queue` instance variable. Read the tests
and the worker class for more information on what you can do inside of the worker.

**bin/worker**

```ruby
#!/usr/bin/env ruby
# encoding: utf-8

trap('INT')  {exit}
trap('TERM') {exit}

require "your_app"
require "queue_classic"
require "my_worker"

MyWorker.new.start
```

#### QC::Worker Details

##### General Idea

The worker class (QC::Worker) is designed to be extended via inheritance. Any of
its methods should be considered for extension. There are a few in particular
that act as stubs in hopes that the user will override them. Such methods
include: `handle_failure() and setup_child()`. See the section near the bottom
for a detailed descriptor of how to subclass the worker.

##### Algorithm

When we ask the worker to start, it will enter a loop with a stop condition
dependent upon a method named `running?` . While in the method, the worker will
attempt to select and lock a job. If it can not on its first attempt, it will
use an exponential back-off technique to try again.

##### Signals

*INT, TERM* Both of these signals will ensure that the running? method returns
false. If the worker is waiting -- as it does per the exponential backoff
technique; then a second signal must be sent.

##### Forking

There are many reasons why you would and would not want your worker to fork.
An argument against forking may be that you want low latency in your job
execution. An argument in favor of forking is that your jobs leak memory and do
all sorts of crazy things, thus warranting the cleanup that fork allows.
Nevertheless, forking is not enabled by default. To instruct your worker to
fork, ensure the following shell variable is set:

```bash
$ export QC_FORK_WORKER='true'
```

One last note on forking. It is often the case that after Ruby forks a process,
some sort of setup needs to be done. For instance, you may want to re-establish
a database connection, or get a new file descriptor. queue_classic's worker
provides a hook that is called immediately after `Kernel.fork`. To use this hook
subclass the worker and override `setup_child()`.

##### LISTEN/NOTIFY

The exponential back-off algorithm will require our worker to wait if it does
not succeed in locking a job. How we wait is something that can vary. PostgreSQL
has a wonderful feature that we can use to wait intelligently. Processes can LISTEN on a channel and be
alerted to notifications. queue_classic uses this feature to block until a
notification is received. If this feature is disabled, the worker will call
`Kernel.sleep(t)` where t is set by our exponential back-off algorithm. However,
if we are using LISTEN/NOTIFY then we can enter a type of sleep that can be
interrupted by a NOTIFY. For example, say we just started to wait for 2 seconds.
After the first millisecond of waiting, a job was enqueued. With LISTEN/NOTIFY
enabled, our worker would immediately preempt the wait and attempt to lock the job. This
allows our worker to be much more responsive. In the case there is no
notification, the worker will quit waiting after the timeout has expired.

LISTEN/NOTIFY is disabled by default but can be enabled by setting the following shell variable:

```bash
$ export QC_LISTENING_WORKER='true'
```

##### Failure

I bet your worker will encounter a job that raises an exception. queue_classic
thinks that you should know about this exception by means of you established
exception tracker. (i.e. Hoptoad, Exceptional) To that end, queue_classic offers
a method that you can override. This method will be passed 2 arguments: the
exception instance and the job. Here are a few examples of things you might want
to do inside `handle_failure()`.

## Instrumentation

QC will log elapsed time, errors and general usage in the form of data.
To customize the output of the log data, override `QC.log` and `QC.log_yield`.
By default, QC uses a simple wrapper around $stdout to put the log data in k=v
format. For instance:

```
lib=queue_classic level=info action=insert_job elapsed=16
```

## Tips and Tricks

### Running Synchronously for tests

Author: [@em_csquared](https://twitter.com/#!/em_csquared)

I was testing some code that started out handling some work in a web request and
wanted to move that work over to a queue.  After completing a red-green-refactor
I did not want my tests to have to worry about workers or even hit the database.

Turns out its easy to get queue_classic to just work in a synchronous way with:

```ruby
def QC.enqueue(function_call, *args)
  eval("#{function_call} *#{args.inspect}")
end
```

Now you can test queue_classic as if it was calling your method directly!


### Dispatching new jobs to workers without new code

Author: [@ryandotsmith (ace hacker)](https://twitter.com/#!/ryandotsmith)

The other day I found myself in a position in which I needed to delete a few
thousand records. The tough part of this situation is that I needed to ensure
the ActiveRecord callbacks were made on these objects thus making a simple SQL
statement unfeasible. Also, I didn't want to wait all day to select and destroy
these objects. queue_classic to the rescue! (no pun intended)

The API of queue_classic enables you to quickly dispatch jobs to workers. In my
case I wanted to call `Invoice.destroy(id)` a few thousand times. I fired up a
Heroku console session and executed this line:

```ruby
Invoice.find(:all, :select => "id", :conditions => "some condition").map {|i| QC.enqueue("Invoice.destroy", i.id) }
```

With the help of 20 workers I was able to destroy all of these records
(preserving their callbacks) in a few minutes.

### Enqueueing batches of jobs

Author: [@ryandotsmith (ace hacker)](https://twitter.com/#!/ryandotsmith)

I have seen several cases where the application will enqueue jobs in batches. For instance, you may be sending
1,000 emails out. In this case, it would be foolish to do 1,000 individual transaction. Instead, you want to open
a new transaction, enqueue all of your jobs and then commit the transaction. This will save tons of time in the
database.

To achieve this we will create a helper method:

```ruby

def qc_txn
  begin
    QC.database.execute("BEGIN")
    yield
    QC.database.execute("COMMIT")
  rescue Exception
    QC.database.execute("ROLLBACK")
    raise
  end
end
```

Now in your application code you can do something like:

```ruby
qc_txn do
  Account.all.each do |act|
    QC.enqueue("Emailer.send_notice", act.id)
  end
end
```

### Scheduling Jobs

Author: [@ryandotsmith (ace hacker)](https://twitter.com/#!/ryandotsmith)

Many popular queueing solution provide support for scheduling. Features like
Redis-Scheduler and the run_at column in DJ are very important to the web
application developer. While queue_classic does not offer any sort of scheduling
features, I do not discount the importance of the concept. However, it is my
belief that a scheduler has no place in a queueing library, to that end I will
show you how to schedule jobs using queue_classic and the clockwork gem.

#### Example

In this example, we are working with a system that needs to compute a sales
summary at the end of each day. Lets say that we need to compute a summary for
each sales employee in the system.

Instead of enqueueing jobs with run_at set to 24hour intervals,
we will define a clock process to enqueue the jobs at a specified
time on each day. Let us create a file and call it clock.rb:

```ruby
handler {|job| QC.enqueue(job)}
every(1.day, "SalesSummaryGenerator.build_daily_report", :at => "01:00")
```

To start our scheduler, we will use the clockwork bin:

```bash
$ clockwork clock.rb
```

Now each day at 01:00 we will be sending the build_daily_report message to our
SalesSummaryGenerator class.

I found this abstraction quite powerful and easy to understand. Like
queue_classic, the clockwork gem is simple to understand and has 0 dependencies.
In production, I create a Heroku process type called clock. This is typically
what my Procfile looks like:

```
worker: rake jobs:work
clock: clockwork clock.rb
```

## Upgrading From Older Versions

### 1.X to 2.X

#### Database Schema Changes

* all queues are in 1 table with a q_name column
* table includes a method column and an args column

#### Producer Changes

* initializing a Queue instance takes a column name instead of a table name

#### Consumer Changes

* all of the worker configuratoin is passed in through the initializer
* rake task uses data from env vars to initialize a worker

### 0.2.X to 0.3.X

* Deprecated QC.queue_length in favor of QC.length
* Locking functions need to be loaded into database via `$ rake qc:load_functions`

Also, the default queue is no longer named jobs,
it is named queue_classic_jobs. Renaming the table is the only change that needs to be made.

```bash
$ psql your_database -c "ALTER TABLE jobs RENAME TO queue_classic_jobs;"
```

Or if you are using Rails' Migrations:

```ruby
class RenameJobsTable < ActiveRecord::Migration

  def self.up
    rename_table :jobs, :queue_classic_jobs
    remove_index :jobs, :id
    add_index :queue_classic_jobs, :id
  end

  def self.down
    rename_table :queue_classic_jobs, :jobs
    remove_index :queue_classic_jobs, :id
    add_index :jobs, :id
  end

end
```

## Hacking on queue_classic

### Dependencies

* Ruby 1.9.2 (tests work in 1.8.7 but compatibility is not guaranteed or supported)
* Postgres ~> 9.0
* Rubygem: pg ~> 0.11.0

### Running Tests

```bash
$ bundle
$ createdb queue_classic_test
$ export QC_DATABASE_URL="postgres://username:pass@localhost/queue_classic_test"
$ rake
```
