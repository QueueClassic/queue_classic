# Queue Classic
__0.3.1__ (beta)

Queue Classic is a postgres-backed queueing library that is focused on
concurrent job locking, minimizing database load & providing a simple &
intuitive user experience.

Queue Classic Features:

* Support for multiple queues with heterogeneous workers
* Utilization of  Postgres' PUB/SUB
* JSON encoding for jobs
* Postgres' rock-solid locking mechanism
* Long term support

## Quick Start

See doc/installation.md for Rails instructions

    $ gem install queue_classic
    psql=# CREATE TABLE queue_classic_jobs (id serial, details text, locked_at timestamp);
    psql=# CREATE INDEX queue_classic_jobs_id_idx ON queue_classic_jobs (id);
    $ rake qc:load_functions
    irb: QC.enqueue "Class.method", "arg"
    $ rake jobs:work

## Hacking on Queue Classic

### Dependencies

* Postgres version 9
* Ruby
* Gems: pg, json

### Running Tests

* Install dependencies: pg, json (see gemspec)
* createdb queue_classic_test
* export DATABASE_URL="postgres://username:pass@localhost/queue_classic_test"
* rake will run the tests (or turn test/)

### Building Documentation

If you are adding new features, please document them in the doc directory. Also,
once you have the markdown in place, please run: ruby doc/build.rb to make HTML
for the docs.

## Other Resources

###[Documentation](https://github.com/ryandotsmith/queue_classic/tree/master/doc)

###[Example Rails App](https://github.com/ryandotsmith/queue_classic_example)

###[Discussion Group](http://groups.google.com/group/queue_classic "discussion group")