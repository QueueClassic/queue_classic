module QC
  class StrategyError; end

  class Worker
    MAX_LOCK_ATTEMPTS = (ENV["QC_MAX_LOCK_ATTEMPTS"] || 5).to_i

    attr_accessor :strategies

    def initialize(args={})
      @queue = QC::Queue.new(ENV["QUEUE"])
      @running = true

      # This is the default list of strategies.
      # If you have your own, append your k:v via the @strategies accessor
      # and specify the k in the args hash.
      strategy = args[:strategy] || :pubsub
      @strategies = {
        :pubsub => PubSub,
        :fork   => Fork
      }

      # This class will assume that the strategy defines
      # start() and lock_job()
      self.class.send(:include, @strategies[strategy])

      handle_signals
    end

    def running?
      @running
    end

    def handle_signals
      %W(INT TERM).each do |sig|
        trap(sig) do
          if running?
            @running = false
          else
            raise Interrupt
          end
        end
      end
    end

    def work
      # How we lock the job is up to the strategy.
      if job = lock_job
        begin
          job.work
        rescue Object => e
          handle_failure(job,e)
        ensure
          @queue.delete(job)
        end
      end
    end

    #override this method to do whatever you want
    def handle_failure(job,e)
      puts "!"
      puts "! \t FAIL"
      puts "! \t \t #{job.inspect}"
      puts "! \t \t #{e.inspect}"
      puts "!"
    end

  end
end
