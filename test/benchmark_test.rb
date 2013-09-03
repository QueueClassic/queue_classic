require File.expand_path("../helper.rb", __FILE__)
Thread.abort_on_exception = true

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
      pool = QC::Pool.new
      queue = QC::Queue.new(:pool => pool)
      worker = QC::Worker.new(:concurrency => 4, :queue => queue)
      worker.running = true
      queue.delete_all
      n = 20
      n.times do
        queue.enqueue("puts", "hello")
      end
      assert_equal(n, queue.count)

      start = Time.now
      n.times.map {worker.fork_and_work}.map(&:join)
      elapsed = Time.now - start

      assert_equal(0, queue.count)
      assert_in_delta(10, elapsed, 3)
    end

  end
end
