namespace :jobs do
  desc "Alias for qc:work"
  task :work  => "qc:work"
end

namespace :qc do
  desc "Start a new worker for the (default or $QUEUE) queue"
  task :work  => :environment do
    QC::Worker.new(
      QC::TABLE_NAME,
      QC::TOP_BOUND,
      QC::FORK_WORKER,
      QC::LISTENING_WORKER,
      QC::MAX_LOCK_ATTEMPTS
    ).start
  end

  desc "Returns the number of jobs in the (default or QUEUE) queue"
  task :length => :environment do
    puts QC::Worker.new(
      QC::TABLE_NAME,
      QC::TOP_BOUND,
      QC::FORK_WORKER,
      QC::LISTENING_WORKER,
      QC::MAX_LOCK_ATTEMPTS
    ).length
  end

  desc "Ensure the database has the necessary functions for QC"
  task :load_functions => :environment do
    QC::Queries.load_functions
  end

  desc "Remove queue_classic functions from database."
  task :drop_functions => :environment do
    QC::Queries.drop_functions
  end
end
