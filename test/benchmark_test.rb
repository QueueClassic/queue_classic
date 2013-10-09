require File.expand_path("../helper.rb", __FILE__)
Thread.abort_on_exception = true

if ENV["QC_BENCHMARK"]
  class BenchmarkTest < QCTest

    def test_enqueue
      n = 10_000
      start = Time.now
      n.times {QC.enqueue("1.odd?")}
      assert_equal(n, QC.count)
      elapsed = Time.now - start
      assert_in_delta(4, elapsed, 1)
    end

    def test_dequeue
      queue = QC::Queue.new
      worker = QC::Worker.new(:concurrency => 4, :queue => queue)
      queue.delete_all
      n = 200

      n.times {queue.enqueue("puts", "hello")}
      assert_equal(n, queue.count)

      start = Time.now
      n.times.map {worker.fork_and_work}.map(&:join)

      elapsed = Time.now - start
      assert_equal(0, queue.count)
      assert_in_delta(10, elapsed, 3)
    end

  end
end
