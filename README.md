# queue_classic
A simple, efficient worker queue for Ruby & PostgreSQL.

Why this over something like Resque. Two reasons:

1. Your jobs can be equeued in the same transaction as other modifications to the database, and will only be processed when everything is commited. This is a hard pattern to develop around for queues done outside your database
2. Less things to run, if you don't already have Redis or a dedicated queue in your stack.

![master](https://github.com/QueueClassic/queue_classic/actions/workflows/main.yaml/badge.svg?branch=master)

[![Gem Version](http://img.shields.io/gem/v/queue_classic.svg?style=flat)](http://badge.fury.io/rb/queue_classic)

**IMPORTANT NOTE: This README is representing the current work for queue_classic, which is generally the pending next version.**

You can always find the latest and previous releases here:

https://github.com/QueueClassic/queue_classic/releases

## Other related projects
If you're interested in this project, you might also want to checkout:

 * [Que](https://github.com/que-rb/que)
 * [GoodJob](https://github.com/bensheldon/good_job)
 * [Delayed Job](https://github.com/collectiveidea/delayed_job)

For a list of other queues (which may or may not be Postgres backed), checkout - https://edgeapi.rubyonrails.org/classes/ActiveJob/QueueAdapters.html

## What is queue_classic?
queue_classic provides a simple interface to a PostgreSQL-backed message queue. queue_classic specializes in concurrent locking and minimizing database load while providing a simple, intuitive developer experience. queue_classic assumes that you are already using PostgreSQL in your production environment and that adding another dependency (e.g. redis, beanstalkd, 0mq) is undesirable.

A major benefit is the ability to enqueue inside transactions, ensuring things are done only when your changes are commited.

## Other related projects
* [Queue Classic Plus](https://github.com/rainforestapp/queue_classic_plus) - adds support for retrying with specific exceptions, transaction processing of jobs, metric collection, etc
* [Queue Classic Admin](https://github.com/QueueClassic/queue_classic_admin) - Admin interface for queue_classic
* [Queue Classic Matchers](https://github.com/rainforestapp/queue_classic_matchers) - RSpec matchers for queue_classic

## Features
* Leverage of PostgreSQL's listen/notify, skip locked, and row locking.
* Support for multiple queues with heterogeneous workers.
* JSON data format.
* Workers can work multiple queues.

### Requirements
For this version, the requirements are as follows:
* Ruby 2.6, 2.7, 3.0, 3.1 - i.e. currently supported Ruby versions
* Postgres ~> 9.6
* Rubygem: pg ~> 1.1

## Table of contents
* [Documentation](https://www.rubydoc.info/gems/queue_classic/)
* [Usage](#usage)
* [Setup](#setup)
* [Upgrade from earlier versions to V3.1](#upgrade-from-earlier-versions)
* [Configuration](#configuration)
  * [JSON](#json)
  * [Logging](#logging)
* [Support](#support)
* [Hacking](#hacking-on-queue_classic)
* [License](#license)

## Usage
There are 2 ways to use queue_classic:

* Producing Jobs
* Working Jobs

### Producing Jobs
#### Simple Enqueue
The first argument is a string which represents a ruby object and a method name. The second argument(s) will be passed along as arguments to the method defined by the first argument. The set of arguments will be encoded as JSON and stored in the database.

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
p_queue = QC::Queue.new("priority_queue")
p_queue.enqueue("Kernel.puts", ["hello", "world"])
```

#### Scheduling for later
There is also the ability to schedule a job to run at a specified time in the future. The job will become processable after the specified time, and will be processed as-soon-as-possible.

```ruby
# Specify the job execution time exactly
QC.enqueue_at(Time.new(2024,01,02,10,00), "Kernel.puts", "hello future")

# Specify the job execution time as an offset in seconds
QC.enqueue_in(60, "Kernel.puts", "hello from 1 minute later")
```

### Working Jobs
There are two ways to work/process jobs. The first approach is to use the Rake task. The second approach is to use a custom executable.

#### Rake Task
Require queue_classic in your Rakefile:

```ruby
require 'queue_classic'
require 'queue_classic/tasks'
```

##### Work all queues
Start the worker via the Rakefile:

```bash
bundle exec rake qc:work
```

##### Work a single specific queue
Setup a worker to work only a specific, non-default queue:

```bash
QUEUE="priority_queue" bundle exec rake qc:work
```

##### Work multiple queues
In this scenario, on each iteration of the worker's loop, it will look for jobs in the first queue prior to looking at the second queue. This means that the first queue must be empty before the worker will look at the second queue.

```bash
QUEUES="priority_queue,secondary_queue" bundle exec rake qc:work
```

#### Custom Worker
This example is probably not production ready; however, it serves as an example of how to leverage the code in the Worker class to fit your non-default requirements.

```ruby
require 'timeout'
require 'queue_classic'

FailedQueue = QC::Queue.new("failed_jobs")

class MyWorker < QC::Worker
  # A job is a Hash containing these attributes:
  # :id Integer, the job id
  # :method String, containing the object and method
  # :args String, the arguments
  # :q_name String, the queue name
  # :scheduled_at Time, the scheduled time if the job was scheduled

  # Execute the job using the methods and arguments
  def call(job)
     # Do something with the job
     ...
  end

  # This method will be called when an exception
  # is raised during the execution of the job.
  # First argument is the job that failed.
  # Second argument is the exception.
  def handle_failure(job, e)
    FailedQueue.enqueue(job[:method], *job[:args])
  end
end

worker = MyWorker.new

trap('INT') { exit }
trap('TERM') { worker.stop }

loop do
  queue, job = worker.lock_job
  Timeout::timeout(5) { worker.process(queue, job) }
end
```

The `qc:work` rake task uses `QC::Worker` by default. However, it's easy to inject your own worker class:

```ruby
QC.default_worker_class = MyWorker
```

## Setup
In addition to installing the rubygem, you will need to prepare your database. Database preparation includes creating a table and loading PL/pgSQL functions. You can issue the database preparation commands using `psql` or use a database migration script.

### Quick Start
```bash{:copy}
gem install queue_classic
createdb queue_classic_test
export QC_DATABASE_URL="postgres://username:password@localhost/queue_classic_test"
ruby -r queue_classic -e "QC::Setup.create"
ruby -r queue_classic -e "QC.enqueue('Kernel.puts', 'hello world')"
ruby -r queue_classic -e "QC::Worker.new.work"
```

### Ruby on Rails Setup
Declare dependencies in Gemfile:

```ruby{:copy}
source 'https://rubygems.org' do
  gem 'queue_classic'
end
```

Install queue_classic, which adds the needed migrations for the database tables and stored procedures:

```bash
rails generate queue_classic:install
bundle exec rake db:migrate
```

#### Database connection
Starting with with queue_classic 3.1, Rails is automatically detected and its connection is used. If you don't want to use the automatic database connection, set this environment variable to false: `export QC_RAILS_DATABASE=false`. 

> **Note:** If you do not share the connection, you cannot enqueue in the same transaction as whatever you're doing in Rails.

**Note on using ActiveRecord migrations:** If you use the migration, and you wish to use commands that reset the database from the stored schema (e.g. `rake db:reset`), your application must be configured with `config.active_record.schema_format = :sql` in `config/application.rb`. If you don't do this, the PL/pgSQL function that queue_classic creates will be lost when you reset the database.

#### Active Job
If you use Rails 4.2+ and want to use Active Job, all you need to do is to set `config.active_job.queue_adapter = :queue_classic` in your `application.rb`. Everything else will be taken care for you. You can now use the Active Job functionality from now.

### Plain Ruby Setup
If you're not using Rails, you can use the Rake task to prepare your database:

```bash{:copy}
# Creating the table and functions
bundle exec rake qc:create

# Dropping the table and functions
bundle exec rake qc:drop
```

#### Database connection
By default, queue_classic will use the `QC_DATABASE_URL` falling back on `DATABASE_URL`. The URL must be in the following format: `postgres://username:password@localhost/database_name`. If you use Heroku's PostgreSQL service, this will already be set. If you don't want to set this variable, you can set the connection in an initializer. **QueueClassic will maintain its own connection to the database.** This may double the number of connections to your database.

## Upgrading from earlier versions
If you are upgrading from a previous version of queue_classic, you might need some new database columns and/or functions. Luckily enough for you, it is easy to do so.

### Ruby on Rails
These two commands will add the newer migrations:

```bash{:copy}
rails generate queue_classic:install
bundle exec rake db:migrate
```

### Rake Task
This rake task will update you to the latest version:

```bash{:copy}
# Updating the table and functions
bundle exec rake qc:update
```

## Configuration
All configuration takes place in the form of environment vars. See [queue_classic.rb](https://github.com/QueueClassic/queue_classic/blob/master/lib/queue_classic.rb#L23-62) for a list of options.

## Logging
By default queue_classic does not talk very much. If you find yourself in a situation where you need to know what's happening inside QC, there are two different kind of logging you can enable: `DEBUG` and `MEASURE`.

### Measure
This will output the time to process and some more statistics. To enable it, set the `QC_MEASURE`:

```bash{:copy}
export QC_MEASURE="true"
```

### Debug
You can enable the debug output by setting the `DEBUG` environment variable:

```bash{:copy}
export DEBUG="true"
```

## Support
If you think you have found a bug, feel free to open an issue. Use the following template for the new issue:

1. List your versions: Ruby, PostgreSQL, queue_classic.
2. Define what you would have expected to happen.
3. List what actually happened.
4. Provide sample codes & commands which will reproduce the problem.

## Hacking on queue_classic
### Running Tests
```bash{:copy}
bundle
createdb queue_classic_test
export QC_DATABASE_URL="postgres://username:pass@localhost/queue_classic_test"
bundle exec rake                      # run all tests
bundle exec ruby test/queue_test.rb   # run a single test
```

## License
Copyright (C) 2010 Ryan Smith

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
