$: << File.expand_path("lib")

require 'benchmark'
require 'queue_classic'

class StringTest
  def self.length(string)
    string.length
  end
end

Benchmark.bm(1) do |x|
  n = 10_000

  x.report "enqueue" do
    n.times { QC.enqueue("StringTest.length", "foo") }
  end

  x.report "forking work" do
    worker = QC::Worker.new
    n.times { worker.fork_and_work }
  end

  x.report "work" do
    worker = QC::Worker.new
    n.times { worker.work }
  end

end

