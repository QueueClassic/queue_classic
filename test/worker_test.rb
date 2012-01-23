require 'helper'

context 'Worker' do
  test "empty string queue names are elimited" do
    worker = QueueClassic::Worker.new( database_url,  "foo", "bar", "", "baz"  )
    assert_equal %w[ foo bar baz ], worker.queue_names
  end

  test "an empty list of queue names results in the default queue being worked" do
    worker = QueueClassic::Worker.new( database_url, *[ ] )
    assert_equal %w[ classic ], worker.queue_names
  end

  test "nil for the list of queue names results in the default queue being worked" do
    worker = QueueClassic::Worker.new( database_url, nil )
    assert_equal %w[ classic ], worker.queue_names
  end

  test "by default only the default queue is worked" do
    worker = QueueClassic::Worker.new( database_url )
    assert_equal %w[ classic ], worker.queue_names
  end
end
