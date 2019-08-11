# Changelog

All notable changes to this project will be documented in this file.

## `master`

Bug fixes:
- [Fix excess memoization of `ConnAdapter` instances causing single global connection shared between threads and connections taken from ActiveRecord becoming shared between its pool and QC](https://github.com/QueueClassic/queue_classic/pull/318)

## [4.0.0-alpha1] - 2019-07-18

Updates:
- [Change to only support >= Postgres 9.6. We will be bringing in newer changes and testing on only 9.6+ going forward.](https://github.com/QueueClassic/queue_classic/pull/307)
- [Change to only support currently supported Ruby versions: 2.4, 2.5 and 2.6.](https://github.com/QueueClassic/queue_classic/pull/305)
- [Use skip-locked](https://github.com/QueueClassic/queue_classic/pull/303)
- [Add abilty to count ready and scheduled jobs](https://github.com/QueueClassic/queue_classic/pull/255)

Bug fixes:
- [Switched project to use CircleCI, as it's way more consistent speed wise](https://github.com/QueueClassic/queue_classic/pull/304)
- [Automatically retry after a connection reset #294](https://github.com/QueueClassic/queue_classic/pull/294)
- [Add tests for installing fresh on rails 5.2.3 + running migrations](https://github.com/QueueClassic/queue_classic/pull/308)
- [Don't recuse Time.now errors](https://github.com/QueueClassic/queue_classic/pull/310)
- Use the jsonb type for the args column from now on. If not available, fall back to json or text.
- `enqueue`, `enqueue_at`, `enqueue_in` return job hash with id.
- Fixed a bug in the offset calculation of `.enqueue_at`.

## [3.0.0rc] - 2014-01-07

- Improved signal handling

## [3.0.0beta] - 2014-01-06

- Workers can process many queues.

## [2.2.3] - 2013-10-24

- Update pg dependency to 0.17.0

## [2.3.0beta] - 2013-09-05 YANKED

- Concurrent job processing.

## [2.2.2] - 2013-08-04

- Update pg dependency to 0.16.0

## [2.2.1] - 2013-07-12

- Force listen/notify on worker
- Notifications happen inside PostgreSQL trigger
- Add rake task for generating rails migrations
- Fix bug related to listening worker

## [2.2.0] - 2013-07-02

- Use json from the stdlib in place of MultiJson.
- Use postgresql's json type for the args column if json type is available
- QC::Worker#handle_failure logs the job and the error
- QC.default_queue= to set your own default queue. (can be used
  in testing to configure a mock queue)
- QC.log now reports time elapsed in milliseconds.

## [2.1.4]

- Update pg dependency to 0.15.1
- Document logging behaviour

## [2.1.3]

- Use MultiJson (Ezekiel Templin: #106)

## [2.1.2]

- Use 64bit ints as default data types in PostgreSQL
- Add process method in worker
- Allow percent-encoded socket paths in DATABASE_URL

## [2.1.1]

- Update pg gem version

## [2.1.0]

- Wrap connection execution in mutex making it thread safe
- Cleanup logging
- Refactor worker class making it more extensible
- Added rdoc style docs for worker class

## [2.0.5]

- Allow term signal to halt the lock_job function

## [2.0.4]

- Provider a connection setter.

## [2.0.3]

- Fix typo :(

## [2.0.2]

- Remove scrolls dependency
- Fix issue with notify not working on non-default queues

## [2.0.1]

## [2.0.0]

- Simpler setup via QC::Setup.create (rake qc:create) & QC::Setup.drop (rake
qc:drop)
- Simpler abstractions in implementation
- Better support for instrumentation via log_yield hook in QC module
- Multiple queues use one table with a queue_name column

## [1.0.2]

- Update to latest okjson as the current has bugs

## [1.0.1]

- Using OkJson instead of any sort of rubygem
- Remove html from docs
- Use parameterised queries
- Don't set application name by default
- Injection attack bug fixed in lock_head()
- Notificaiton get sent on seperate chans for disjoint queues

## [1.0.0rc1] - 2011-08-29

- Removed json gem and relying on ruby 1.9.2's stdlib
- Added better documentation

## [0.3.6pre]

- Added listen/notify support configured by $QC_LISTENING_WORKER otherwise uses Kernel.sleep()

## [0.3.5pre] - 2011-08-27

- Removed debug statement. Mistake!

## [0.3.4pre]

- Added logging configured by $VERBOSE or $QC_VERBOSE.
- Added a method setup_child that gets called right after a worker forks.
- Removed database helper methods: create_table, drop_table, silence_warnings.
- Removed queue connection helper methods. Status should be discoverd by psql or the likes.

## [0.3.3pre]

- Removed PUB/SUB
- Added GC after working a job
- Added support for a database_url other than $DATABASE_URL. $QC_DATABASE_URL
- Added exp backoff configured by $QC_MAX_LOCK_ATTEMPTS (default = 5)
- Added option for forking worker configured by $QC_FORK_WORKER (default = false)

## [0.3.2] - 2011-08-03

- Fixed bug which caused workers to consume 2 connections. Now they only consume 1
- Added a rake file for tests
- Added support for postgres:///db_name DATABASE_URLs

## [0.3.1] - 2011-04-27

- Added query interface for introspection success
- Moved the locking of jobs into the DB as a PG function. SELECT lock_head()
- Added requirement for DB connection. MUST BE URI i.e. DATABASE_URL=postgres://user:pass@localhost/db_name
- Added rake qc:create_queue. This task will add a new table. Use this for multiple queues.
- Added a bit of randomness to the lock_head() function. Helps you scale to a hilarious number of workers.
- Added support for trapping INT and TERM signals in the worker. ^C to stop after finished and ^C^C to kill.
- Renamed the jobs table to queue_classic_jobs
- Renamed the jobs channel to queue_classic_jobs
- Added support for multiple queues

## [0.2.2] - 2011-02-26

- Fixed problems with enqueueing a list of parameters.

## [0.2.1] - 2011-02-22

- Added method for handling errors.
- Added ability to enqueue a Job instance. Makes retrying jobs easier.
- Added delete_all.
- Fixed connection algorithm. 1 connection per process.
- Fixed API for enqueue. Now accepting 1 arg or many args.

## [0.2.0] - 2011-02-17

- Beta Release
- Added method for handling failed jobs
- Added Benchmarks
- Removed logging
- Moved the Job class into it's own file

## [0.1.6] - 2011-02-03

- Early release
