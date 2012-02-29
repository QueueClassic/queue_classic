module QC

  # This test helper is used to run the queues in owr test environments in order to test the
  # correct behaviour.
  #
  # We provide two helper methods <tt>work_jobs</tt> and <tt>clear_jobs</tt>. The <tt>work_jobs</tt>
  # method is used to run all the jobs of the given queues and <tt>clear_jobs</tt> method is used to
  # remove all the jobs from the given queues.
  module TestHelper

    # This method is used to run all the jobs of the given queues
    #
    # [queues]
    #   By default we use QC the default queue of queued_classic but you can add
    #   any queues that you want.
    def work_jobs(queues = nil)
      queues ||= [QC]
      queues.each do |queue|
        previous_queue= ENV["QUEUE"]
        ENV["QUEUE"]= queue.database.table_name

        worker = QC::Worker.new
        number_of_works = QC::Queue.length

        number_of_works.times { worker.work }

        ENV["QUEUE"]= previous_queue
      end
    end

    # This method clears all the queues passed as parameter. If you call it without any
    # parameter it will only clear jobs for QC queue.
    #
    # [queues]
    #   An array of queues that you want to clear. If you don't provide this parameter
    #   then we clear the default queue (QC)
    def clear_jobs(queues = nil)
      queues ||= [QC]
      queues.each do |queue|
        queue.delete_all
      end
    end

  end
end