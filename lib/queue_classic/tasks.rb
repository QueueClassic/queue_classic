namespace :jobs do

  task :work  => :environment do
    QC::Worker.new.start
  end

end

namespace :qc do

  task :work  => :environment do
    QC::Worker.new.start
  end

  desc "Returns the number of jobs in the (default) queue"
  task :jobs => :environment do
    puts QC.length
  end

  task :load_functions => :environment do
    db = QC::Database.new
    db.load_functions
    db.disconnect
  end

end
