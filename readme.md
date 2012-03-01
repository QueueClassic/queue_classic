# queue_classic
v1.0.0

queue_classic is a PostgreSQL-backed queueing library that is focused on
concurrent job locking, minimizing database load & providing a simple &
intuitive user experience.

queue_classic features:

* Support for multiple queues with heterogeneous workers
* Utilization of Postgres' PUB/SUB
* JSON encoding for jobs
* Forking workers
* Postgres' rock-solid locking mechanism
* Fuzzy-FIFO support (1)
* Long term support

1.Theory found here: http://www.cs.tau.ac.il/~shanir/nir-pubs-web/Papers/Lock_Free.pdf

## Proven

I wrote queue_classic to solve a production problem.  My problem was that I needed a
queueing system that wouldn't fall over should I decide to press it nor should it freak out
if I attached 100 workers to it. However, my problem didn't warrant adding an additional service.
I was already using PostgreSQL to manage my application's data, why not use PostgreSQL to pass some messages?
PostgreSQL was already handling thousands of reads and writes per second anyways. Why not add 35 more
reads/writes per second to my established performance metric?

queue_classic handles over **3,000,000** jobs per day. It does this on Heroku's Ronin Database.

## Quick Start

See doc/installation.md for Rails instructions

```bash
$ createdb queue_classic_test
$ psql queue_classic_test
psql- CREATE TABLE queue_classic_jobs (id serial, details text, locked_at timestamp);
$ export QC_DATABASE_URL="postgres://username:password@localhost/queue_classic_test"
$ gem install queue_classic
$ ruby -r queue_classic -e "QC::Database.new.load_functions"
$ ruby -r queue_classic -e "QC.enqueue('Kernel.puts', 'hello world')"
$ ruby -r queue_classic -e "QC::Worker.new.start"
```

## Configure

```bash
# Enable logging.
$VERBOSE

# Specifies the database that queue_classic will rely upon.
$QC_DATABASE_URL || $DATABASE_URL

# Fuzzy-FIFO
# For strict FIFO set to 1. Otherwise, worker will
# attempt to lock a job in this top region.
# Default: 9
$QC_TOP_BOUND

# If you want your worker to fork a new
# child process for each job, set this var to 'true'
# Default: false
$QC_FORK_WORKER

# The worker uses an exp backoff algorithm
# if you want high throughput don't use Kernel.sleep
# use LISTEN/NOTIFY sleep. When set to true, the worker's
# sleep will be preempted by insertion into the queue.
# Default: false
$QC_LISTENING_WORKER

# The worker uses an exp backoff algorithm. The base of
# the exponent is 2. This var determines the max power of the
# exp.
# Default: 5 which implies max sleep time of 2^(5-1) => 16 seconds
$QC_MAX_LOCK_ATTEMPTS

# This var is important for consumers of the queue.
# If you have configured many queues, this var will
# instruct the worker to bind to a particular queue.
# Default: queue_classic_jobs --which is the default queue table.
$QUEUE
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

## Other Resources

* [Discussion Group](http://groups.google.com/group/queue_classic "discussion group")
* [Documentation](https://github.com/ryandotsmith/queue_classic/tree/master/doc)
* [Example Rails App](https://github.com/ryandotsmith/queue_classic_example)
* [Slide Deck](http://dl.dropbox.com/u/1579953/talks/queue_classic.pdf)
