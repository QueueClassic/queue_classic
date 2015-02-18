require File.expand_path("../helper.rb", __FILE__)

class QueueTest < QCTest

  ResetError = Class.new(PGError)

  def test_enqueue
    QC.enqueue("Klass.method")
  end

  def test_respond_to
    assert_equal(true, QC.respond_to?(:enqueue))
  end

  def test_connection_adapter_in_constructor
    adapter = QC::ConnAdapter.new
    queue = QC::Queue.new("test", conn_adapter: adapter)
    assert_equal queue.conn_adapter, adapter
  end

  def test_lock
    queue = QC::Queue.new("queue_classic_jobs")
    queue.enqueue("Klass.method")
    job = queue.lock
    # See helper.rb for more information about the large initial id number.
    assert_equal((2**34).to_s, job[:id])
    assert_equal("queue_classic_jobs", job[:q_name])
    assert_equal("Klass.method", job[:method])
    assert_equal([], job[:args])
  end

  def test_lock_when_empty
    assert_nil(QC.lock)
  end

  def test_lock_with_future_job_with_enqueue_in
    QC.enqueue_in(2, "Klass.method")
    assert_nil QC.lock
    sleep 2
    job = QC.lock
    assert_equal("Klass.method", job[:method])
    assert_equal([], job[:args])
  end

  def test_lock_with_future_job_with_enqueue_at_with_a_time_object
    future = Time.now + 2
    QC.enqueue_at(future, "Klass.method")
    assert_nil QC.lock
    until Time.now >= future do sleep 0.1 end
    job = QC.lock
    assert_equal("Klass.method", job[:method])
    assert_equal([], job[:args])
  end

  def test_lock_with_future_job_with_enqueue_at_with_a_float_timestamp
    offset = (Time.now + 2).to_f
    QC.enqueue_at(offset, "Klass.method")
    assert_nil QC.lock
    sleep 2
    job = QC.lock
    assert_equal("Klass.method", job[:method])
    assert_equal([], job[:args])
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
    queue.delete(queue.lock[:id])
    assert_equal(0, queue.count)
  end

  def test_repair_after_error
    queue = QC::Queue.new("queue_classic_jobs")
    queue.conn_adapter = QC::ConnAdapter.new
    queue.enqueue("Klass.method")
    assert_equal(1, queue.count)
    conn = queue.conn_adapter.connection
    def conn.exec(*args); raise(PGError); end
    def conn.reset(*args); raise(ResetError)  end
    # We ensure that the reset method is called on the connection.
    assert_raises(PG::Error, ResetError) {queue.enqueue("Klass.other_method")}
    queue.conn_adapter.disconnect
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

  def test_multi_threaded_server_can_specified_connection
    adapter1 = QC::ConnAdapter.new
    adapter2 = QC::ConnAdapter.new
    q1 = q2 = nil

    QC.default_conn_adapter = adapter1

    t1 = Thread.new do
      QC.default_conn_adapter = adapter1
      q1 = QC::Queue.new('queue1').conn_adapter
    end

    t2 = Thread.new do
      QC.default_conn_adapter = adapter2
      q2 = QC::Queue.new('queue2').conn_adapter
    end

    t1.join
    t2.join

    assert_equal adapter1, q1
    assert_equal adapter2, q2
  end

  def test_multi_threaded_server_each_thread_acquires_unique_connection
    q1 = q2 = nil

    t1 = Thread.new do
      q1 = QC::Queue.new('queue1').conn_adapter
    end

    t2 = Thread.new do
      q2 = QC::Queue.new('queue2').conn_adapter
    end

    t1.join
    t2.join

    refute_equal q1, q2
  end

  def test_enqueue_triggers_notify
    adapter = QC.default_conn_adapter
    adapter.execute('LISTEN "' + QC.queue + '"')
    adapter.send(:drain_notify)

    msgs = adapter.send(:wait_for_notify, 0.25)
    assert_equal(0, msgs.length)

    QC.enqueue("Klass.method")
    msgs = adapter.send(:wait_for_notify, 0.25)
    assert_equal(1, msgs.length)
  end

end
