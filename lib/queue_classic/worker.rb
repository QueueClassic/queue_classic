require 'servolux'
require 'stringio'
module QueueClassic
  #
  # The Worker style we are going to use here is the fork-per-job pattern.
  # The main process wil wait for jobs to show up on the queue and when they do,
  # it will fork off a child process to do the acutal processing. This is
  # managed via the Servolux::Piper class.
  #
  class Worker
    include Logable

    # The names of the queues this worker is attached to.
    attr_reader :queue_names

    # Create a new worker process that connects to the given database and starts
    # monitoring the given queues for job messages.
    def initialize( db_url, *qnames )
      @queue_names = cleanup_queue_names( qnames )
      @db_url      = db_url
    end

    # The main method of the worker. It runs the lifecycle of the worker.
    #
    # timeout - how long to wait on each queue to see if there ate notification
    #           of work
    #
    # The worker's lifecycle is:
    #
    # 1. startup  : This connects to the session and creates a new consumer
    #               for each queue on the list
    # 2. loop     : Message are receved from the queues and converted to jobs
    #               and run in child processes
    # 3. shutdown : any child processes are cleaned up, and then this process
    #               shuts down its conumes, the session and exits.
    #
    def work( timeout = 1.0 )
      @timeout = timeout
      startup
      work_loop
      shutdown
    end

    # do pre loop items 
    def startup
      procline "Starting up"
      @session   = ::QueueClassic::Session.new( @db_url )
      @consumers = @queue_names.map { |qn| @session.consumer_for( qn ) }
    end

    # What should be done every iteration of work
    #
    # work loop will loop over each consumer and burn down the first queue that
    # has messages in it. It will then restart on the first queue in the list
    #
    def work_loop
      loop do
        @consumers.each do |consumer|
          procline "waiting for message from #{consumer.consumer_id}"
          count = consumer.each_message( :wait, @timeout ) do |msg|
            work_payload( msg.payload )
          end

          # if we did work on this queue, ones that have higher priority
          # my have jobs, so we return from the itereation to try a higher
          # priority queue.
          break if count > 0
        end
      end
    end

    # after loop items
    def shutdown
      procline "Shutting down"
      @session.close
    end

    #######
    private
    #######

    # Lifted straight from resque
    # Sets the procline and logs it
    def procline( s )
      $0 = "queue_classic: #{s}"
      logger.info $0
    end


    # Process a message, assuming it is a Job
    #
    # If the message cannot be converted to a Job return that as such
    #
    # Return the message about the message processing
    def work_payload( payload )
      job   = ::QueueClassic::RunnablePayload.new( payload )
      piper = ::Servolux::Piper.new

      piper.child  { child( piper, job ) }
      final_message = piper.parent { parent( piper ) }

      piper.close
      return final_message
    rescue ::QueueClassic::RunnablePayload::Error => e
      logger.error "payload #{payload} is not a valid pyaload : #{e}"
      e.message
    end

    # What to do in the parent
    #
    def parent(piper)
      procline "Forked job to #{piper.pid} at #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}"
      Process.wait(piper.pid)
      msg = StringIO.new
      while d = piper.gets do
        msg.write( d )
      end
      puts "child message: #{msg.string}"
      return msg.string
    end

    # What to do in the child
    #
    def child(piper, job)
      procline "Processing #{job} since #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}"
      piper.puts job.run
    rescue Object => o
      piper.puts o
    ensure
      exit!
    end

    # Resolve the queue names into seemingly good names
    #
    # qnames - the list of queue names to resolve
    #
    # A valid queue name is a non-empty string that is not 'default'
    #
    def cleanup_queue_names( qnames )
      return [ ::QueueClassic::Queue.default_name ] if qnames.nil?

      qnames = qnames.map       { |q| q.to_s.strip  }
      qnames = qnames.delete_if { |q| q.length == 0 }

      return [ ::QueueClassic::Queue.default_name ] if qnames.empty?

      return qnames
    end
  end
end
