# Queue Classic
__Beta 0.3.0__

__Queue Classic 0.3.0 is in Beta.__ I have been using this library with 30-150 Heroku workers and have had great results.

I am using this in production applications and plan to maintain and support this library for a long time.

Queue Classic is a queueing library for Ruby apps (Rails, Sinatra, Etc...) Queue Classic features a blocking dequeue, database maintained locks and
no ridiculous dependencies. As a matter of fact, Queue Classic only requires the __pg__ and __json__.

[Discussion Group](http://groups.google.com/group/queue_classic)

[Wiki](https://github.com/ryandotsmith/queue_classic/wiki)

## Installation

1. $ gem install queue_classic
2. psql=# CREATE TABLE queue_classic_jobs (id serial, details text, locked_at timestamp);
3. psql=# CREATE INDEX queue_classic_jobs_id_idx ON queue_classic_jobs (id);
4. $ rake qc:load_functions
5. irb: QC.enqueue "Class.method", "arg"
6. $ rake jobs:work

### Upgrade from < 0.2.3 to 0.3.0

  $ psql your_database
  your_database=# ALTER TABLE jobs RENAME TO queue_classic_jobs;

### Dependencies

  Postgres version 9

  Ruby (gems: pg, json)
