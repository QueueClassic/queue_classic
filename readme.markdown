# Queue Classic

## Enqueue
To place a job onto the queue, you should specify a class and a class method. The syntax should be:

` QC.enqueue('Class.method', :arg1 => 'value1', :arg2 => 'value2')`

## Worker
The worker will lookup the method in the class and call it with the supplied arguments.
Any sort of exception should be rescued in the class method.

## FAQ
Why doesn't your queue retry failed jobs?
> I believe the Class method should handle any sort of exception.  Also, I think
that the model you are working on should know about it's state. For instance, if you are
creating jobs for the emailing of newsletters; put a emailed_at column on your newsletter model
and then right before the job quits, touch the emailed_at column.
