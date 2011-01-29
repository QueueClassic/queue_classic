# Queue Classic
**Alpha 0.1.1**

Queue Classic 0.1.1 is not ready for production. However, it is under active development and I expect a beta release within the following months.
Queue Classic is an alternative queueing library for Ruby apps (Rails, Sinatra, Etc...) It features **async** job polling, database maintained locks and
no ridiculous dependencies. As a matter of fact, Queue Classic only requires the pg and json.

## Installation
`gem install queue_classic`
Add `require 'queue_classic/tasks'` to your Rakefile.
If you don't want to bother with a Rakefile just create a worker object and start it manually.
`
worker = QC::Worker.new
worker.start
`


## Enqueue
To place a job onto the queue, you should specify a class and a class method. The syntax should be:

` QC.enqueue('Class.method', :arg1 => 'value1', :arg2 => 'value2')`
The job gets stored in the jobs table with a details field set to: {job: Class.method, params: {arg1: value1, arg2: value2}} (json)

## Dequeue
When you start a worker, it starts a loop that performs a blocking dequeue call. The call to dequeue will return when a job lock attempt was made.
If your worker got the lock, then you work the job. Otherwise, you return and then continue the iteration in hopes of acquiring a lock.

## Working the Job
The worker will lookup the method in the class and call it with the supplied arguments.
Any sort of exception should be rescued in the class method.

## FAQ
Why does this project seem incomplete? Will you make it production ready?
> I started this project on 1/24/2011. Check back soon! Also, feel free to contact me to find out how passionate I am about queueing.

Why doesn't your queue retry failed jobs?
> I believe the Class method should handle any sort of exception.  Also, I think
that the model you are working on should know about it's state. For instance, if you are
creating jobs for the emailing of newsletters; put a emailed_at column on your newsletter model
and then right before the job quits, touch the emailed_at column.

Can I use this library with 50 Heroku Workers?
> Maybe. I haven't tested 50 workers yet. But it is definitely a goal for Queue Classic. I am not sure when,
but you can count on this library being able to handle all Heroku can throw at it.

Are you a Heroku Engineer?
> Yes.
