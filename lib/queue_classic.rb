require 'queue_classic/init'
QC::Queue.instance.setup :data_store => QC::DurableArray.new(:database => ENV["DATABASE_URL"])

