task :environment

namespace :jobs do
  desc "Alias for qc:work"
  task :work  => "qc:work"
end

namespace :qc do
  desc "Start a new worker for the (default or $QUEUE) queue"
  task :work  => :environment do
    @worker = QC::Worker.new

    trap('INT') do
      $stderr.puts("Received INT. Shutting down.")
      if !@worker.running
        $stderr.puts("Worker has stopped running. Exit.")
        exit(1)
      end
      @worker.stop
    end

    trap('TERM') do
      $stderr.puts("Received Term. Shutting down.")
      @worker.stop
    end

    @worker.start
  end

  desc "Returns the number of jobs in the (default or QUEUE) queue"
  task :count => :environment do
    puts QC::Worker.new.queue.count
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
end
