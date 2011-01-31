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
end
