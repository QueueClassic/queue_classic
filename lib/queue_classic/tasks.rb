require 'queue_classic'

namespace :jobs do
  desc 'Alias for qc:work'
  task :work => 'qc:work'
end

namespace :qc do
  def enviro_queues
    queues = (ENV['QUEUES'] || ENV['QUEUE']).to_s.split(",")
  end

  desc 'Start a new worker attaching to the QC_DATABASE_URL server and QUEUE or QUEUES queues'
  task :work => :environment do
    worker = QueueClassic::Worker.new( ENV['QC_DATABASE_URL'], *enviro_queues() )
    worker.work
  end

  desc 'Returns the number of jobs in the (default or QUEUE or QUEUES) queue'
  task :jobs => :environment do
    session = QueueClassic::Session.new( ENV['QC_DATABASE_URL'] )
    session.queues.sort_by { |q| q.name }.each do |q|
      p_stats = q.counts.map { |k,v| "#{k}: #{"%6d" % v}" }.sort
      puts "QUEUE: #{q.name.rjust(8)} => #{p_stats.join(' ')}"
    end
  end

  desc "Install queue_classic into an existing database"
  task :setup => :environment do
    require 'queue_classic/bootstrap'
    QueueClassic::Bootstrap.setup( ENV['QC_DATABASE_URL'] )
  end

  desc "Uninstall queue_classic from the database"
  task :teardown => :environment do
    require 'queue_classic/bootstrap'
    QueueClassic::Bootstrap.teardown( ENV['QC_DATABASE_URL'] )
  end
end
