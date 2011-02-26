require File.expand_path("../helper.rb", __FILE__)

context "QC::Api" do
  setup { clean_database }

  test "enqueue takes a job without params" do
    QC.enqueue "Notifier.send"

    job = QC.dequeue
    assert_equal({"job" => "Notifier.send", "params" => [] }, job.details)
  end

  test "enqueue takes a hash" do
    QC.enqueue "Notifier.send", {:arg => 1}

    job = QC.dequeue
    assert_equal({"job" => "Notifier.send", "params" => [{"arg" => 1}] }, job.details)
  end

  test "enqueue takes a job" do
    h = {"id" => 1, "details" => {"job" => 'Notifier.send'}.to_json, "locked_at" => nil}
    job = QC::Job.new(h)
    QC.enqueue(job)

    job = QC.dequeue
    assert_equal({"job" => "Notifier.send", "params" => []}, job.details)
  end

  test "enqueue takes a job and maintain params" do
    h = {"id" => 1, "details" => {"job" => 'Notifier.send', "params" => ["1"]}.to_json, "locked_at" => nil}
    job = QC::Job.new(h)
    QC.enqueue(job)

    job = QC.dequeue
    assert_equal({"job" => "Notifier.send", "params" => ["1"]}, job.details)
  end

  test "query finds job with matching signature" do
    end

end

