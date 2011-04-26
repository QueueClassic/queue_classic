require File.expand_path("../helper.rb", __FILE__)

context "Queue" do

  setup { init_db }

  test "Queue class responds to enqueue" do
    QC::Queue.enqueue("Klass.method")
  end

  test "Queue class has a default table name" do
    QC::Queue.enqueue("Klass.method")
  end

  test "Queue class responds to dequeue" do
    QC::Queue.enqueue("Klass.method")
    assert_equal "Klass.method", QC::Queue.dequeue.signature
  end

  test "Queue class responds to delete" do
    QC::Queue.enqueue("Klass.method")
    job = QC::Queue.dequeue
    QC::Queue.delete(job)
  end

  test "Queue class responds to delete_all" do
    2.times { QC::Queue.enqueue("Klass.method") }
    job1,job2 = QC::Queue.dequeue, QC::Queue.dequeue
    QC::Queue.delete_all
  end

  test "Queue class return the length of the queue" do
    2.times { QC::Queue.enqueue("Klass.method") }
    assert_equal 2, QC::Queue.length
  end

  test "Queue class finds jobs using query method" do
    QC::Queue.enqueue("Something.hard_to_find")
    jobs = QC::Queue.query("Something.hard_to_find")
    assert_equal 1, jobs.length
    assert_equal "Something.hard_to_find", jobs.first.signature
  end

  test "queue instance responds to enqueue" do
    QC::Queue.enqueue("Something.hard_to_find")
    init_db(:custom_queue_name)
    @queue = QC::Queue.new(:custom_queue_name)
    @queue.enqueue "Klass.method"
    @queue.disconnect
  end

  test "queue only uses 1 connection per class" do
    QC::Queue.length
    QC::Queue.enqueue "Klass.method"
    QC::Queue.delete QC::Queue.dequeue
    QC::Queue.dequeue
    assert_equal 1, QC.connection_status[:total]
  end

end
