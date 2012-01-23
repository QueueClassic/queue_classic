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
  $ gem install queue_classic
  $ queue_classic -d postgres://username:password@localhost/queue_classic_test setup
  $ queue_classic -d postgres://username:password@localhost/queue_classic_test producer 'hello world'
  $ queue_classic -d postgres://username:password@localhost/queue_classic_test consumer
```

## Configure

```bash

# Specifies the database that queue_classic will rely upon.
# Something like
#  postgres://user:password@host/dbname
#
# If you have a .pgpass file you queue_classic will that up so you can
# specify postgres://host/dbname and if you have your .pgpass setup
# all will be good:
# http://www.postgresql.org/docs/9.1/static/libpq-pgpass.html
$QC_DATABASE_URL

# This var is important for consumers of the queue.
# If you have configured many queues, this var will
# instruct the worker to bind to a particular queue(s).
# Default: classic
# You can have multiple queues, and in this case, use the
# $QUEUES variable. For instance:
#   $QUEUES=foo,bar,baz
# Will connect to all 3 queues.
$QUEUE


```

## Hacking on queue_classic

### Dependencies

* Ruby 1.9.2 (tests work in 1.8.7 but compatibility is not guaranteed or supported)
* Postgres ~> 9.0
* Rubygems
** pg ~> 0.11.0
** json ~> 1.6.1

### Running Tests

```bash
  $ bundle
  $ createdb queue_classic_test
  $ export QC_DATABASE_URL="postgres://username:pass@localhost/queue_classic_test"
  $ rake
```

### Building Documentation

If you are adding new features, please document them in the doc directory. Also,
once you have the markdown in place, please run: ruby doc/build.rb to make HTML
for the docs.

## Other Resources

###[Discussion Group](http://groups.google.com/group/queue_classic "discussion group")

###[Documentation](https://github.com/ryandotsmith/queue_classic/tree/master/doc)

###[Example Rails App](https://github.com/ryandotsmith/queue_classic_example)

###[Slide Deck](http://dl.dropbox.com/u/1579953/talks/queue_classic.pdf)
