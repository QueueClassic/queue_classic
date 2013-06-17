require File.expand_path("../helper.rb", __FILE__)

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

  def test_concurrent_dequeue
    Thread.abort_on_exception = true

    queue = QC::Queue.new
    num_threads = 8
    n = 10_000

    n.times do
      queue.enqueue("1.odd?", [])
    end
    assert_equal(n, queue.count)

    start = Time.now
    num_threads.times.map do
      Thread.new do
        worker = QC::Worker.new(queue)
        worker.running = true
        (n / num_threads).times do
          worker.work(num_threads)
        end
      end
    end.map(&:join)
    assert_equal(0, queue.count)

    elapsed = Time.now - start
    assert_in_delta(5, elapsed, 3)
  end

end
