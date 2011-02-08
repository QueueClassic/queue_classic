$: << File.expand_path("lib")
$: << File.expand_path("test")

ENV["DATABASE_URL"] = 'queue_classic_test'

require 'queue_classic'
require 'database_helpers'

require 'benchmark'
include DatabaseHelpers
clean_database

class String
  def self.length(string)
    string.length
  end
end

Benchmark.bm(10) do |x|
  n = 10_000
  n.times { QC.enqueue("String.length", "foo") }

  x.report do
    worker = QC::Worker.new
    n.times { worker.work }
  end

end

