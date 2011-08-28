### The Worker

#### General Idea

The worker class (QC::Worker) is designed to be extended via inheritance. Any of
it's methods should be considered for extension. There are a few in particular
that act as stubs in hopes that the user will override them. Such methods
include: `handle_failure() and setup_child()`. See the section near the bottom
for a detailed descriptor of how to subclass the worker.

#### Algorithm

When we ask the worker to start, it will enter a loop with a stop condition
dependent upon a method named `running?`. While in the method, the worker will
attempt to select and lock a job. If it can not on its first attempt, it will
use an exponential back-off technique to try again.

#### Signals

*INT, TERM* Both of these signals will ensure that the running? method returns
false. If the worker is waiting -- as it does per the exponential backoff
technique; then a second signal must be sent.

#### Forking

There are many reasons why you would and would not want your worker to fork.
An argument against forking may be that you want low latency in your job
execution. An argument in favor of forking is that your jobs leak memory and do
all sorts of crazy things, thus warranting the cleanup that fork allows.
Nevertheless, forking is not enabled by default. To instruct your worker to
fork, ensure the following shell variable is set:

```bash
$ export QC_FORK_WORKER='true'
```

One last note on forking. It is often the case that after Ruby forks a process,
some sort of setup needs to be done. For instance, you may want to re-establish
a database connection, or get a new file descriptor. queue_classic's worker
provides a hook that is called immediately after `Kernel.fork`. To use this hook
subclass the worker and override `setup_child()`.

#### LISTEN/NOTIFY

The exponential back-off algorithm will require our worker to wait if it does
not succeed in locking a job. How we wait is something that can vary. PostgreSQL
has a wonderful feature that we can use to wait intelligently. Processes can LISTEN on a channel and be
alerted to notifications. queue_classic uses this feature to block until a
notification is received. If this feature is disabled, the worker will call
`Kernel.sleep(t)` where t is set by our exponential back-off algorithm. However,
if we are using LISTEN/NOTIFY then we can enter a type of sleep that can be
interrupted by a NOTIFY. For example, say we just started to wait for 2 seconds.
After the first millisecond of waiting, a job was enqueued. With LISTEN/NOTIFY
enabled, our worker would immediately preempt the wait and attempt to lock the job. This
allows our worker to be much more responsive. In the case there is no
notification, the worker will quit waiting after the timeout has expired.

LISTEN/NOTIFY is disabled by default but can be enabled by setting the following shell variable:

```bash
$ export QC_LISTENING_WORKER='true'
```

#### Failure

I bet your worker will encounter a job that raises an exception. Queue_classic
thinks that you should know about this exception by means of you established
exception tracker. (i.e. Hoptoad, Exceptional) To that end, Queue_classic offers
a method that you can override. This method will be passed 2 arguments: the
exception instance and the job. Here are a few examples of things you might want
to do inside `handle_failure()`.

```ruby
  def handle_failure(job, exception)
    Exceptional.handle(exception, "Background Job Failed" + job.inspect)

    HoptoadNotifier.notify(
        :error_class   => "Background Job",
        :error_message => "Special Error: #{e.message}",
        :parameters    => job.details
    )

    # Log to STDOUT (Heroku Logplex listens to stdout)
    puts job.inspect
    puts exception.inspect
    puts exception.backtrace

    # Retry the job
    @queue.enqueue(job)
  end
end
```

#### Creating a Subclass of QC::Worker

There are many reasons to customize the worker to do exactly what you need.
QC::Worker was designed to be sub-classed. This section will show a common
approach to customizing a worker. Somewhere in your project --the lib directory
works good in a Rails project; you will create a file, call it worker.rb

```ruby
# lib/worker.rb
require 'queue_classic'

class MyWorker < QC::Worker

  def setup_child
    log("fork establishing database connection")
    ActiveRecord::Base.establish_connection
  end

end
```

Now that you have created a new worker, you will have to start MyWorker instead
of QC::Worker. Lets take a look at the different ways to run a worker.

#### Running the Worker

In the installation doc, we showed that including `require 'queue_classic/tasks`
into your Rakefile would expose `rake jobs:work`. The task defined in
queue_classic will simply instantiate QC::Worker and call start on that
instance. This is fine for default setups. However, if you have a customized
worker or you do not want to use Rake, then the following example will help you
get your worker started.

For example, lets say that we have a simple Ruby program. We will create a bin
directory in this project and inside that directory a file named worker.

```ruby
#!/usr/bin/env ruby

$: << File.expand_path('lib')

require 'queue_classic'
require 'my_worker'

MyWorker.new.start
```

Now we can make the file executable and run it using bash.

```bash
$ chmod +x bin/worker
$ ./bin/worker
```

Now we are running our custom worker. The next example will show a similar
approach but using Rake. In this example, I'll assume we are working with a
Rails project.

Create a new file lib/tasks/my_worker.rake

```ruby
require 'queue_classic'
require 'queue_classic/tasks'
require 'my_worker'
# OR you can define MyWorker in this file.

namespace :jobs do
  task :work  => :environment do
    MyWorker.new.start
  end
end
```
