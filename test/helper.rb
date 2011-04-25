$: << File.expand_path("lib")
$: << File.expand_path("test")

ENV["DATABASE_ADAPTER"] = 'postgres'
ENV["DATABASE_URL"] = 'queue_classic_test'

require 'queue_classic'
require 'database_helpers'

require 'minitest/unit'
MiniTest::Unit.autorun

def set_data_store(store=nil)
  QC::Queue.instance.setup(
    :data_store => (
      store || QC::DurableArray.new(:adapter => ENV["DATABASE_ADAPTER"], :database => ENV["DATABASE_URL"])
    )
  )
end

