require File.expand_path("../helper.rb", __FILE__)

class QueueTest < QCTest

  def setup
    init_db
  end

  def teardown
    QC.conn.disconnect
  end

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
    expected = {:id=>(2**34).to_s, :method=>"Klass.method", :args=>[], :priority => QC::Queue::DEFAULT_PRIORITY}
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

  def test_delete_all_by_queue_name
    p_queue = QC::Queue.new(:name => "priority_queue")
    s_queue = QC::Queue.new(:name => "secondary_queue")
    p_queue.enqueue("Klass.method")
    s_queue.enqueue("Klass.method")
    assert_equal(1, p_queue.count)
    assert_equal(1, s_queue.count)
    p_queue.delete_all
    assert_equal(0, p_queue.count)
    assert_equal(1, s_queue.count)
  ensure
    p_queue.conn.disconnect
    s_queue.conn.disconnect
  end

  def test_queue_instance
    queue = QC::Queue.new(:name => "queue_classic_jobs")
    queue.enqueue("Klass.method")
    assert_equal(1, queue.count)
    queue.delete(queue.lock[:id])
    assert_equal(0, queue.count)
  ensure
    queue.conn.disconnect
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
    c = QC::Conn.new
    c.execute('LISTEN "' + QC::Queue::QUEUE_NAME + '"')
    c.send(:drain_notify)
    msgs = c.send(:wait_for_notify, 0.25)
    assert_equal(0, msgs.length)

    QC.enqueue("Klass.method")
    msgs = c.send(:wait_for_notify, 0.25)
    assert_equal(1, msgs.length)
  ensure
    c.disconnect
  end

  def test_setting_priority_values
    QC.enqueue("Klass.method1", priority: 5)
    assert_equal(QC.lock[:priority], 5)
    QC.enqueue("Klass.method2", priority: 10)
    assert_equal(QC.lock[:priority], 10)
  end

  def test_priority_defaults
    QC.enqueue("Klass.priority0")
    job = QC.lock
    assert_equal(job[:priority], QC::Queue::DEFAULT_PRIORITY)
  end

  def test_priority_ordering
    QC.enqueue("Klass.method1", priority: 1)
    QC.enqueue("Klass.method2", priority: 5)
    QC.enqueue("Klass.method3", priority: 10)
    assert_equal(QC.lock[:method], "Klass.method3")
    assert_equal(QC.lock[:method], "Klass.method2")
    assert_equal(QC.lock[:method], "Klass.method1")
  end

  def test_remove_options_hash_if_empty
    QC.enqueue("Klass.method1", 1, priority: 5)
    assert_equal(QC.lock[:args], [1])
    QC.enqueue("Klass.method1", 1, {})
    assert_equal(QC.lock[:args], [1, {}])
  end
end
