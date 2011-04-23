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
  task :create_queue, :name :needs => :environment do |t,args|
    name = args[:name].to_sym
    QC::Database.create_queue(name)
  end
end
