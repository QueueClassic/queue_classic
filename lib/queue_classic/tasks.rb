namespace :jobs do
  task :work  => :environment do
    QC::Worker.new.start
  end
end
namespace :qc do
  task :work do
    QC::Worker.new.start
  end
  task :jobs do
    QC.queue_length
  end
  task :init_db do
    array = QC::Queue.instance.data_store
    database = array.database
    database.init_db
  end
end
