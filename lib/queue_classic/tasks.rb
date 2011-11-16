namespace :jobs do

  task :work  => :environment do
    QC::Worker.new.start
  end

end

namespace :qc do

  task :work  => :environment do
    QC::Worker.new.start
  end

  task :jobs => :environment do
    QC.queue_length
  end

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
