namespace :jobs do

  desc 'Alias for qc:work'
  task :work  => 'qc:work'

end

namespace :qc do

  desc 'Start a new worker for the (default or QUEUE) queue'
  task :work  => :environment do
    QC::Worker.new.start
  end

  desc 'Returns the number of jobs in the (default or QUEUE) queue'
  task :jobs => :environment do
    puts QC::Queue.new(ENV['QUEUE']).length
  end

  desc 'Ensure the database has the necessary functions for QC'
  task :load_functions => :environment do
    db = QC::Database.new
    db.load_functions
    db.disconnect
  end

  task :remove_functions => :environment do
    db = QC::Database.new
    db.remove_functions
    db.disconnect
  end

end
