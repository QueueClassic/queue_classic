module QC
  module Worker::PubSub

    def start
      work while running?
    end

    def lock_job
      job = nil
      until job
        if job = @queue.dequeue
          @queue.database.unlisten
        else
          @queue.database.listen
          @queue.database.wait_for_notify
        end
      end
      job
    end

  end
end
