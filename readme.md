# Queue Classic
1.0.0

Queue Classic is a PostgreSQL-backed queueing library that is focused on
concurrent job locking, minimizing database load & providing a simple &
intuitive user experience.

Queue Classic Features:

* Support for multiple queues with heterogeneous workers
* Utilization of Postgres' PUB/SUB
* JSON encoding for jobs
* Forking workers
* Postgres' rock-solid locking mechanism
* Long term support

## Quick Start

See doc/installation.md for Rails instructions

```bash
  $ createdb queue_classic_test
  $ psql queue_classic_test
  psql=# CREATE TABLE queue_classic_jobs (id serial, details text, locked_at timestamp);
  psql=# CREATE INDEX queue_classic_jobs_id_idx ON queue_classic_jobs (id);
  $ export QC_DATABASE_URL="postgres://username:password@localhost/queue_classic_test"
  $ gem install queue_classic
  $ ruby -r queue_classic -e "QC::Database.new.load_functions"
  $ ruby -r queue_classic -e "QC.enqueue("Kernel.puts", "hello world")"
  $ ruby -r queue_classic -e "QC::Worker.new.start"
```

## Hacking on Queue Classic

### Dependencies

* Ruby 1.9.2
* Postgres ~> 9.0
* Rubygems: pg ~> 0.11.0

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

###[Documentation](https://github.com/ryandotsmith/queue_classic/tree/master/doc)

###[Example Rails App](https://github.com/ryandotsmith/queue_classic_example)

###[Discussion Group](http://groups.google.com/group/queue_classic "discussion group")
