require File.expand_path("../helper.rb", __FILE__)

if ENV["QC_BENCHMARK"]
  class BenchmarkTest < QCTest
    BENCHMARK_SIZE = Integer(ENV.fetch("QC_BENCHMARK_SIZE", 10_000))
    BENCHMARK_MAX_TIME_DEQUEUE = Integer(ENV.fetch("QC_BENCHMARK_MAX_TIME_DEQUEUE", 30))
    BENCHMARK_MAX_TIME_ENQUEUE = Integer(ENV.fetch("QC_BENCHMARK_MAX_TIME_ENQUEUE", 5))

    def test_enqueue
      start = Time.now
      BENCHMARK_SIZE.times do
        QC.enqueue("1.odd?")
      end
      assert_equal(BENCHMARK_SIZE, QC.count)

      elapsed = Time.now - start
      assert_operator(elapsed, :<, BENCHMARK_MAX_TIME_ENQUEUE)
    end

    def test_dequeue
      worker = QC::Worker.new
      worker.running = true
      BENCHMARK_SIZE.times do
        QC.enqueue("1.odd?")
      end
      assert_equal(BENCHMARK_SIZE, QC.count)

      start = Time.now
      BENCHMARK_SIZE.times do
        worker.work
      end
      elapsed = Time.now - start

      assert_equal(0, QC.count)
      assert_operator(elapsed, :<, BENCHMARK_MAX_TIME_DEQUEUE)
    end

  end
end
