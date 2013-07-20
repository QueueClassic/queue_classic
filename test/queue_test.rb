require File.expand_path("../helper.rb", __FILE__)

class QueueTest < QCTest

  def test_enqueue
    QC.enqueue("Klass.method")
  end

  def test_respond_to
    assert_equal(true, QC.respond_to?(:enqueue))
  end

  def test_lock
    QC.enqueue("Klass.method")

    # See helper.rb for more information about the large initial id
    # number.
    expected = {:id=>(2**34).to_s, :method=>"Klass.method", :args=>[], :locked_by => 1}
    assert_equal(expected, QC.lock(1))
  end

  def test_lock_when_empty
    assert_nil(QC.lock(1))
  end

  def test_lock_when_worker_has_died
    QC.enqueue("Klass.method")
    j = QC::Conn.execute "UPDATE queue_classic_jobs SET locked_at = NOW(), locked_by = 1 RETURNING *"
    assert_equal j['id'], QC.lock(2)[:id]
  end

  def test_count
    QC.enqueue("Klass.method")
    assert_equal(1, QC.count)
  end

  def test_delete
    QC.enqueue("Klass.method")
    assert_equal(1, QC.count)
    QC.delete(QC.lock(1)[:id])
    assert_equal(0, QC.count)
  end

  def test_delete_all
    QC.enqueue("Klass.method")
    QC.enqueue("Klass.method")
    assert_equal(2, QC.count)
    QC.delete_all
    assert_equal(0, QC.count)
  end

  def test_delete_all_by_queue_name
    p_queue = QC::Queue.new("priority_queue")
    s_queue = QC::Queue.new("secondary_queue")
    p_queue.enqueue("Klass.method")
    s_queue.enqueue("Klass.method")
    assert_equal(1, p_queue.count)
    assert_equal(1, s_queue.count)
    p_queue.delete_all
    assert_equal(0, p_queue.count)
    assert_equal(1, s_queue.count)
  end

  def test_queue_instance
    queue = QC::Queue.new("queue_classic_jobs")
    queue.enqueue("Klass.method")
    assert_equal(1, queue.count)
    queue.delete(queue.lock(1)[:id])
    assert_equal(0, queue.count)
  end

  def test_repair_after_error
    queue = QC::Queue.new("queue_classic_jobs")
    queue.enqueue("Klass.method")
    assert_equal(1, queue.count)
    connection = QC::Conn.connection
    c = connection.raw_connection
    def c.exec(*args)
      raise PGError
    end
    assert_raises(PG::Error) { queue.enqueue("Klass.other_method") }
    assert_equal(1, queue.count)
    queue.enqueue("Klass.other_method")
    assert_equal(2, queue.count)
  rescue PG::Error
    QC::Conn.disconnect
    assert false, "Expected to QC repair after connection error"
  end

  def test_custom_default_queue
    queue_class = Class.new do
      attr_accessor :jobs
      def enqueue(method, *args)
        @jobs ||= []
        @jobs << method
      end
    end

    queue_instance = queue_class.new
    QC.default_queue = queue_instance

    QC.enqueue("Klass.method1")
    QC.enqueue("Klass.method2")

    assert_equal ["Klass.method1", "Klass.method2"], queue_instance.jobs
  ensure
    QC.default_queue = nil
  end

  def test_enqueue_triggers_notify
    QC::Conn.execute('LISTEN "' + QC::QUEUE + '"')
    QC::Conn.send(:drain_notify)

    msgs = QC::Conn.send(:wait_for_notify, 0.25)
    assert_equal(0, msgs.length)

    QC.enqueue("Klass.method")
    msgs = QC::Conn.send(:wait_for_notify, 0.25)
    assert_equal(1, msgs.length)
  end

end
