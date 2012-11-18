require 'queue_classic'
require "base64"

module QC
  module Rails

    def self.encode(job)
      Base64.encode64(Marshal.dump(job))
    end

    def self.decode(arguments)
      job_dump = Base64.decode64(arguments.last)
      Marshal.load(job_dump)
    end

    class Queue
      def push(job)
        arguments = [job.class.name, QC::Rails.encode(job)]
        qc_queue.enqueue('QC::Rails::Job.run', *arguments)
      end

      def qc_queue
        @qc_queue ||= QC.default_queue
      end
      private :qc_queue
    end

    class Job
      def self.run(*arguments)
        job = QC::Rails.decode(arguments)
        job.run
      end
    end

  end
end
