# Scheduling Jobs

Many popular queueing solution provide support for scheduling. Features like
Redis-Scheduler and the run_at column in DJ are very important to the web
application developer. While queue_classic does not offer any sort of scheduling
features, I do not discount the importance of the concept. However, it is my
belief that a scheduler has no place in a queueing library, to that end I will
show you how to schedule jobs using queue_classic and the clockwork gem.

## Example

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
In production, I create a heroku process type called clock. This is typically
what my Procfile looks like:

```bash
worker: rake jobs:work
clock: clockwork clock.rb
```
