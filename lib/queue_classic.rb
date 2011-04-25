require 'queue_classic/init'
QC::Queue.instance.setup :data_store => QC::DurableArray.new(:adapter => ENV["DATABASE_ADAPTER"], :database => ENV["DATABASE_URL"])

