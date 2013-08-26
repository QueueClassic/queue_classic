if Rake::Task.task_defined? "qc:count"
  ActiveSupport::Deprecation.warn <<-MSG
queue_classic Rake tasks are now loaded automatically for Rails applications.
Loading the tasks yourself is deprecated. Please update your Rakefile and remove:

  require 'queue_classic'
  require 'queue_classic/tasks'

  MSG
else
  task :environment

  namespace :jobs do
    desc "Alias for qc:work"
    task :work  => "qc:work"
  end

  namespace :qc do
    desc "Start a new worker for the (default or $QUEUE) queue"
    task :work  => :environment do
      trap('INT') {exit}
      trap('TERM') {@worker.stop}
      @worker = QC::Worker.new
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
  end
end
