# frozen_string_literal: true

task :environment

namespace :jobs do
  desc "Alias for qc:work"
  task :work  => "qc:work"
end

namespace :qc do
  desc "Start a new worker for the (default or $QUEUE / $QUEUES) queue"
  task :work  => :environment do
    build_worker.start
  end

  desc "Work off jobs in the (default or $QUEUE / $QUEUES) queue"
  task :work_off  => :environment do
    build_worker.work_off
  end

  desc "Returns the number of jobs in the (default or $QUEUE / $QUEUES) queue"
  task :count => :environment do
    puts QC.default_queue.count
  end

  desc "Setup queue_classic tables and functions in database"
  task :create => :environment do
    QC::Setup.create
  end

  desc "Remove queue_classic tables and functions from database."
  task :drop => :environment do
    QC::Setup.drop
  end

  desc "Update queue_classic tables and functions in database"
  task :update => :environment do
    QC::Setup.update
  end

  def build_worker
    @worker = QC.default_worker_class.new

    trap('INT') do
      $stderr.puts("Received INT. Shutting down.")      
      abort("Worker has stopped running. Exit.") unless @worker.running
      @worker.stop
    end

    trap('TERM') do
      $stderr.puts("Received Term. Shutting down.")
      @worker.stop
    end

    @worker
  end
end
