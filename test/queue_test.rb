require File.expand_path("../helper.rb", __FILE__)

context "QC::Queue" do

  setup do
    QC::Queue.instance.delete_all
  end

  test "queue is a singleton" do
    assert_equal QC::Queue, QC::Queue.instance.class
  end

  test "queue takes a data_store" do
    assert_equal QC::DurableArray, QC::Queue.instance.data_store.class
  end

  test "queue repsonds to length" do
    QC::Queue.instance.enqueue "job","params"
    assert_equal 1, QC::Queue.instance.length
  end

  test "can delete all" do
    QC::Queue.instance.enqueue "job","params"
    QC::Queue.instance.enqueue "job","params"

    assert_equal 2, QC::Queue.instance.length
    QC::Queue.instance.delete_all
    assert_equal 0, QC::Queue.instance.length
  end

  test "query finds jobs with matching signature" do
    QC::Queue.instance.enqueue "Notifier.send", "params"

    jobs = QC::Queue.instance.query("Notifier.send")
    assert_equal 1, jobs.length
    assert_equal "Notifier.send", jobs.first.signature
  end

end
