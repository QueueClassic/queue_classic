require File.expand_path("../helper.rb", __FILE__)

class QueueTest < QCTest

  def test_enqueue
    QC.enqueue("Klass.method")
  end

  def test_lock
    QC.enqueue("Klass.method")
    expected = {:id=>"1", :method=>"Klass.method", :args=>[]}
    assert_equal(expected, QC.lock)
  end

  def test_lock_when_empty
    assert_nil(QC.lock)
  end

  def test_count
    QC.enqueue("Klass.method")
    assert_equal(1, QC.count)
  end

  def test_delete
    QC.enqueue("Klass.method")
    assert_equal(1, QC.count)
    QC.delete(QC.lock[:id])
    assert_equal(0, QC.count)
  end

  def test_delete_all
    QC.enqueue("Klass.method")
    QC.enqueue("Klass.method")
    assert_equal(2, QC.count)
    QC.delete_all
    assert_equal(0, QC.count)
  end

  def test_queue_instance
    queue = QC::Queue.new("queue_classic_jobs", 1, false)
    queue.enqueue("Klass.method")
    assert_equal(1, queue.count)
    queue.delete(queue.lock[:id])
    assert_equal(0, queue.count)
  end

end
