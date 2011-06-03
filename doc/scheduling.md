# Scheduling Jobs


Many popular queueing solution provide support for scheduling. Features like
Redis-Scheduler,the run_at column in DJ are very important to the web
application developer. While Queue Classic does not offer any sort of scheduling
features, I do not discount the importance of the concept. However, it is my
belief that a scheduler has no place in a queueing library, to that end I will
show you how to schedule jobs using Queue Classic and the Clockwork gem.


## Example 1

In this example, we are working with a system that needs to compute a sales
summary at the end of each day. Lets say that we need to compute a summary for
each sales employee in the system.

Instead of enqueueing jobs with run_at set to 24hour intervals,
we will define a clock process to enqueue the jobs at a specified
time on each day.


Create a file and call it clock.rb

```ruby

  handler {|job| QC.enqueue(job)}
  every(1.day, "SalesSummaryGenerator.build_daily_report", :at => "01:00")

```
