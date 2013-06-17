require File.expand_path("../helper.rb", __FILE__)

if ENV["QC_BENCHMARK"]
  class BenchmarkTest < QCTest
  
    def test_enqueue
      n = 10_000
      start = Time.now
      n.times do
        QC.enqueue("1.odd?", [])
      end
      assert_equal(n, QC.count)
  
      elapsed = Time.now - start
      assert_in_delta(4, elapsed, 1)
    end
  
    def test_dequeue
      worker = QC::Worker.new
      worker.running = true
      n = 10_000
      n.times do
        QC.enqueue("1.odd?", [])
      end
      assert_equal(n, QC.count)
  
      start = Time.now
      n.times do
        worker.work
      end
      elapsed = Time.now - start
  
      assert_equal(0, QC.count)
      assert_in_delta(10, elapsed, 3)
    end
  
  end
end
