$: << File.expand_path("lib")
$: << File.expand_path("test")

ENV["DATABASE_URL"] ||= 'postgres://ryandotsmith:@localhost/queue_classic_test'

require 'queue_classic'
require 'benchmark'

class String
  def self.length(string)
    string.length
  end
end

array = QC::Queue.instance.data_store
database = array.database
database.init_db

Benchmark.bm(10) do |x|
  n = 10_000

  x.report "enqueue" do
    n.times { QC.enqueue("String.length", "foo") }
  end

  x.report "work" do
    worker = QC::Worker.new
    n.times { worker.work }
  end

end

