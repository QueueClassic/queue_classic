module QC
  module Worker::Fork

    def start
      while running?
        cpid = fork { work }
        puts "fork #{cpid}"
        Process.wait(cpid)
      end
    end

    def lock_job
      attempts = 0
      job = nil
      until job
        job = @queue.dequeue
        if job.nil?
          puts "exp backoff"
          attempts += 1
          if attempts < MAX_LOCK_ATTEMPTS
            sleep(2**attempts)
            next
          else
            break
          end
        else
        end
      end
      job
    end

  end
end
