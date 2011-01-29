namespace :jobs do
  task :work  => :environment do
    QC::Worker.new.start
  end
end
