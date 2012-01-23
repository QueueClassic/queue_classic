# Damn, now that's a pull request.  What is the difference:

## New Benefits of this feature branch?

In no particular order:

* Removal of all the static class variables from the original code base.
* Automatic Queue creation, when a producer or consumer (see terminology below)
  attaches to a queue, it is automatically created, like beanstalk.
* NOTIFY/LISTEN is now per queue based, and notifications are only received by
  consumers that are listening on the appropriate channel.
* Stats on what is being done where. We can do a little bit of introspection
  into the system now.
* Connected clients are recognized via the pg_stats_activity table and used
  to populate fields in the *stats*.
* The relative_top of the Fuzzy FIFO algorithm is now automatically calculated
  based upon the stats table.
* Runnable Jobs are created from Mesasge bodies enableing queue classice to be
  used wither with its own style jobs or with Resqueue style jobs (see the json
  format for the payload).
* The Worker forking process is implemented using Servolux::Piper and can listen
  on multiple queues in the same way that Resque can listen on multipel queues.

There are probably a few more things going on and I cannot remember them right
now.

## Terminology

The big one is that I decided to stop using the term Job and switch to Message.

The other new concepts are a Session, a Producer and a Consumer. There is no
single class that may both add to the queue and remove from it. 

You start out by creating a Session, which is the fundamental connection to
Postgres with some added sugar. 

    session = QueueClassic::Session.new( 'postgres://user:pass@host/db' )

You create Producers and Consumers from the Session for a given queue.

    producer = session.producer_for( 'my-queue' )
    consumer = session.consumer_for( 'my-queue' )

## Message Life Cycle

A message follows a life cycle very similar to that of one in
[beanstalk](http://kr.github.com/beanstalkd/). 

1. A Producer *put* a mesasge onto the queue and it is in the *ready* state,
   which means it is available for processing.
2. A Consumer *reserve* a message, which means that it is going to process it.
3. A Consumer *finalize* a message, which removes it from the queue and puts it
   into the history table.

Currently the concepts of *kick* and *bury* are not implemented as they do not
exist in the release version of queue_classic.

## Database Structure

First, all the tables, functions, etc. are installed under their own schema so
that they do not conflict with any other parts of the system.

And now there are 4 tables involved instead of 1.

### Queues

This is a new lookup table to keep track of the queues in the system. Pretty
simple, I would imagine it would stay pretty small. New queue entries should be
created by the *use_queue( 'queue-name' )* function. This function will populate
the new stat rows for the queue, see the *stats* table further down.

### Messages 

This is what use to be queue\_classic\_jobs. It doesn't lose anything, and gains a
few columns

* queue\_id - foreign key to queues table above
* payload  - this is essentially what was the 'description' field before
* ready\_at - the time that the message is ready for processing, essentially
  created at
* reserved\_at - this is what used to be locked_at
* reserved\_by - a string indicating what worker process reserved the message,
  this is pulled from pg_stat_activity.application_name
* reserved\_ip - the ip address of the worker process that reserved the message,
  this is pulled by using inet_client_addr()

There is a potential optimization here, the table is created with
*fillfactor=50*, since for the basic life cycle of this table, the message is
inserted once, then updated once and then deleted once. setting the
*fillfactor=50* will hopefully allow postgresql an efficiency boost in storing
the updated tuple for the row on the same page as the original, and then it can
all be reaped when the page becomes free.

This table should have an extremely high churn.

### Messages History

This is a new table, and may not be strictly necessary, It is exactly the same
as *messages* with 2 additional columns:

* finalized\_at - the time when the message was inserted into this table
* finalized\_note - this is a text string that can be used to put some additional
  data about how the message was finalized. Error status, exception dump, okay
  status etc.

This table, is essentially a write once table, the rows are never updated.

### Stats

This is a new table, it shows some stats about the system and it use internally
by some of the PL/pgsql functions and is updated by triggers and some other
functions which can reset the stats should they get out of whack because one of
us operators does something foolish.

* queue\_id - foreign key to the queues table
* name - the name of the stat
* value - the value of the stat

Currently there are only 5 stats, and they exist for each queue. That is, each
of the numbers below is per queue.

* ready\_count - the number of rows in *messages* that are ready for processing
  for a queue
* reserved\_count - the number of rows in *messages* that are currently being
  processed
* finalized\_count - the number of rows in *messages_history*
* producer\_count - the number of postgres clients attached that say they are
  putting messages onto the queue.
* consumer\_count - the number of postgres clients attached that say they are
  taking messagses off of the queue.

All of the stats are updated automatically. The ready/reserved/finalized are
updated via triggers on the *messages* and *messages_history* table. The
producer/consumer counts are updated automatically from the Ruby program as an
affect of creating a Session object.

The *consumer_count* and the *ready_count* for a queue are used internally in
the *reserve()* function to automatically determine the *relative_top* for use
in the fuzzy FIFO algorithm.

This table exists mainly to support the *reserve()* function so that it doesn't
have to do a select count() on the messages table which can be quite expensive
when the table has lots of rows in it.

Over time I would imagine that the stats would get out of whack a bit, so there
are two functions that may be invoked to set the stats to their true values.

    select * from update_participant_counts()
    select * from update_queue_counts()

Those may be invoked at anytime and to fix all the stats should they become
skewed.

## Performance (Back of the Envelope)

These numbers are on my 2011 MBP. With a *messages* table with over 1,000,000
rows in it.

### Putting messages onto the queues

On the performance side, inserting into the database is a little more expensive
since there are some triggers to update stats and a few more columns, but not by
much.

    jeremy@[local]] 23:01:10> explain analyze select * from put('classic', 'some data');
                                                 QUERY PLAN
    ----------------------------------------------------------------------------------------------------
     Function Scan on put  (cost=0.25..0.26 rows=1 width=124) (actual time=0.265..0.265 rows=1 loops=1)
     Total runtime: 0.274 m

If you compare this to the values that are in
[performance.html](performance.html), and I have no idea if that is a valid
comparison, it is slower, and roughly equivalent. Sub millisecond is not bad.

There is now an *example/qc-producer* program which just does
*put('classic','data')* into the messages table as fast as it can, on my machine
this is in the roughly 2,000 mps, so if it was going flat out that rate would
insert *172 Million* records in a day. Not that anyone has that many messages in
queue_classic. And that goes above and beyond the *3 Million* records a day in
the original [readme](readme.html).


### Reserving messages for processing

On this side of things, its looks like things were sped up a bit, most likely by
using the data in the *stats* table.

    [jeremy@[local]] 23:12:05> explain analyze select * from reserve('classic');
                                                   QUERY PLAN
    --------------------------------------------------------------------------------------------------------
     Function Scan on reserve  (cost=0.25..0.26 rows=1 width=124) (actual time=0.675..0.676 rows=1 loops=1)
     Total runtime: 0.686 ms

Again, if you compare this to [performance.html](performance.html), we're faster
in this case, and roughly equivalent. Sub millisecond is not bad.

If we compare the fundamental query we see that it was speed up quite a bit,
although I have no idea why. There is an index on queue\_id and in this analyze
it is still doing a Sequence Scan.

    [jeremy@[local]] 23:14:01> explain analyze select * from messages where queue_id = 1 and reserved_at is null limit 1 offset 10 for update nowait;
                                                            QUERY PLAN
    --------------------------------------------------------------------------------------------------------------------------
     Limit  (cost=0.38..0.42 rows=1 width=58) (actual time=0.054..0.054 rows=1 loops=1)
       ->  LockRows  (cost=0.00..39189.63 rows=1020638 width=58) (actual time=0.033..0.052 rows=11 loops=1)
             ->  Seq Scan on messages  (cost=0.00..28983.25 rows=1020638 width=58) (actual time=0.008..0.015 rows=11 loops=1)
                   Filter: ((reserved_at IS NULL) AND (queue_id = 1))
     Total runtime: 0.080 ms

### Finalizing the message

Where we gained time on the reserving, we lose it again on the finalizing. Now,
instead of just deleting a row, we are moving it to the *messages_history*
table. So that expense needs to be taken into account as well.

    [jeremy@[local]] 23:24:57> explain analyze select * from finalize('classic',3,'blah');
                                                   QUERY PLAN
    ---------------------------------------------------------------------------------------------------------
     Function Scan on finalize  (cost=0.25..0.26 rows=1 width=164) (actual time=0.346..0.347 rows=1 loops=1)
     Total runtime: 0.356 ms

### Performance Thoughts

All in all, I think the performance of this version is basically the same as the
previous one, some back of the envelope testing shows that it is totally the
database that is the bottle neck if you think there is one. My assumption is
that the whatever process is executed based upon receiving a message from
queue_classic is going to take longer then receiving the message itself.

And with that thought, I ran some experiments numbers and it looks like the
ratios of 1 producer for 3-5 consumers might be a good ratio. That roughly falls
in line with the costs of insertion and selection from the database.

So, with the current benchmark of 3,000,000 jobs a day through the system,
that's just 35 messages a second, which is totally doable.

