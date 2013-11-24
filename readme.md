# queue_classic

v2.2.1

queue_classic provides a simple interface to a PostgreSQL-backed message queue. queue_classic specializes in concurrent locking and minimizing database load while providing a simple, intuitive developer experience. queue_classic assumes that you are already using PostgreSQL in your production environment and that adding another dependency (e.g. redis, beanstalkd, 0mq) is undesirable.

Features:

* Leverage of PostgreSQL's listen/notify & row locking.
* Support for multiple queues with heterogeneous workers.
* JSON data format.
* Concurrent job processing using forking workers.
* [Reduced contention FIFO design](http://www.cs.tau.ac.il/~shanir/nir-pubs-web/Papers/Lock_Free.pdf).

Contents:

* [Documentation](http://rubydoc.info/gems/queue_classic/2.2.1/frames)
* [Usage](#usage)
* [Setup](#setup)
* [Configuration](#configuration)
* [Support](#support)
* [Hacking](#hacking-on-queue_classic)
* [License](#license)

## Usage

There are 2 ways to use queue_classic.

* Producing Jobs
* Working Jobs

### Producing Jobs

The first argument is a string which represents a ruby object and a method name. The second argument(s) will be passed along as arguments to the method invocation defined by the first argument. The set of arguments will be encoded as JSON in the database.

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

# This method uses a non-default queue.
p_queue = QC::Queue.new(name: "priority_queue")
p_queue.enqueue("Kernel.puts", ["hello", "world"])
```

### Working Jobs

There are two ways to work jobs. The first approach is to use the Rake task. The second approach is to use a custom executable. Each approach provides a set of configuration options accessable through the processes' environment:

* `$CONCURRENCY=1` - The number of child processes to run concurrently.
* `$FORK_WORKER=false` - Fork on each job execution. Enabled if `$CONCURRENCY` > 1
* `$QUEUE=default` - The name of the queue(s) to process.
* `$TOP_BOUND=9` - The section of the queue that is elgible for dequeue operations. Setting this value to 1 will ensure a strict FIFO ordering.

#### Working multiple queues

You can specify multiple queues for the process to work separated by commas.
E.g:

``` bash
$ QC_CONCURRENCY=4 QUEUE=high,medium,low bundle exec rake qc:work
$ QC_CONCURRENCY=4 QUEUE=high,medium bundle exec rake qc:work
$ QC_CONCURRENCY=4 QUEUE=high bundle exec rake qc:work
```

Queues are depleted in the order that they are given. So the second queue will
go through all the jobs from the high queue first, before working the medium ones.

#### Rake Task

Require queue_classic in your Rakefile. If you are using Rails, the tasks will
be loaded automatically.

```ruby
require 'queue_classic'
require 'queue_classic/tasks'
```

Start the worker via the Rakefile.

```bash
$ bundle exec rake qc:work
```

Setup a worker to work a non-default queue while processing 4 jobs at a time.

```bash
$ QC_CONCURRENCY=4 QUEUE="priority_queue" bundle exec rake qc:work
```

#### Custom Worker

This example is probably not production ready; however, it serves as an example of how to leverage the code in the Worker class to fit your non-default requirements.

```ruby
require 'timeout'
require 'queue_classic'

FailedQueue = QC::Queue.new(name: "failed_jobs")

class MyWorker < QC::Worker
 	def handle_failure(job, e)
		FailedQueue.enqueue(job[:method], *job[:args])
 	end
end

worker = MyWorker.new

trap('INT') {exit}
trap('TERM') {worker.stop}

loop do
	job = worker.lock_job
	Thread.new do
	  Timeout::timeout(5) { worker.process(job) }
	end
end
```

## Setup

In addition to installing the rubygem, you will need to prepare your database. Database preparation includes creating a table and loading PL/pgSQL functions. You can issue the database preparation commands using `PSQL(1)` or use a database migration script.

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

Declare dependencies in Gemfile.

```ruby
source "http://rubygems.org"
gem "queue_classic", "2.2.1"
```

By default, queue_classic will use the QC_DATABASE_URL falling back on DATABASE_URL. The URL must be in the following format: `postgres://username:password@localhost/database_name`.  If you use Heroku's PostgreSQL service, this will already be set. If you don't want to set this variable, you can set the connection in an initializer. **QueueClassic will maintain its own connection to the database.** This may double the number of connections to your database. Set QC::Conn.connection to share the connection between Rails & QueueClassic

```ruby
require 'queue_classic'
QC::Conn.connection = ActiveRecord::Base.connection.raw_connection
```

Next you need to run the queue classic generator to create the database
migration. This will setup the necessary table to use queue classic.

```
rails generate queue_classic:install
rake db:migrate
```

**Note on using ActiveRecord migrations:** If you use the migration, and you wish to use commands that reset the database from the stored schema (e.g. `rake db:reset`), your application must be configured with `config.active_record.schema_format = :sql` in `config/application.rb`.  If you don't do this, the PL/pgSQL function that queue_classic creates will be lost when you reset the database.

### Rake Task Setup

Alternatively, you can use the Rake task to prepare your database.

```bash
# Creating the table and functions
$ bundle exec rake qc:create

# Dropping the table and functions
$ bundle exec rake qc:drop
```

## Configuration

All configuration takes place in the form of environment vars. See [queue_classic.rb](https://github.com/ryandotsmith/queue_classic/blob/master/lib/queue_classic.rb#L23-62) for a list of options.

## JSON

If you are running PostgreSQL 9.2 or higher, queue_classic will use the [json](http://www.postgresql.org/docs/9.2/static/datatype-json.html) datatype for storing arguments. Versions 9.1 and lower will use the 'text' column. If you have installed queue_classic prior to version 2.1.4 and are running PostgreSQL >= 9.2, run the following to switch to using the json type:
```
alter table queue_classic_jobs alter column args type json using (args::json);
```

## Logging

By default queue_classic does not talk very much.
If you find yourself in a situation where you need to know what's happening inside QC,
you can enable the debug output by setting the `DEBUG` environment variable:

```
export DEBUG="true"
```

## Support

If you think you have found a bug, feel free to open an issue. Use the following template for the new issue:

1. List Versions: Ruby, PostgreSQL, queue_classic.
2. Define what you would have expcted to happen.
3. List what actually happened.
4. Provide sample codes & commands which will reproduce the problem.

If you have general questions about how to use queue_classic, send a message to the mailing list:

https://groups.google.com/d/forum/queue_classic

## Hacking on queue_classic

[![Build Status](https://drone.io/github.com/ryandotsmith/queue_classic/status.png)](https://drone.io/github.com/ryandotsmith/queue_classic/latest)

### Dependencies

* Ruby 1.9.2 (tests work in 1.8.7 but compatibility is not guaranteed or supported)
* Postgres ~> 9.0
* Rubygem: pg ~> 0.11.0
* For JRuby, see [queue_classic_java](https://github.com/bdon/queue_classic_java)

### Running Tests

```bash
$ bundle
$ createdb queue_classic_test
$ export QC_DATABASE_URL="postgres://username:pass@localhost/queue_classic_test"
$ rake
```

## License

Copyright (C) 2010 Ryan Smith

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
