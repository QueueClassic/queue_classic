require 'helper'

context 'Session' do
  setup do
    setup_db
    @session = QueueClassic::Session.new( database_url )
  end

  teardown do
    teardown_db
  end

  test "session raises an error if the schema does not exist" do
    assert_raises QueueClassic::Error do
      QueueClassic::Session.new( database_url, "qc" )
    end
  end

  test "returns a list of all the known queues" do
    queues = @session.queues
    assert_equal 1, queues.size
    assert_equal 'default', queues.first.name
  end

  test "session can create a queue if it doesn't exist" do
    queues = @session.queues
    assert_equal 1, queues.size
    q2 = @session.use_queue( 'foo' )
    assert_equal 'foo', q2.name

    queues = @session.queues
    assert_equal 2, queues.size
  end

  test "session does not create a new queue if one by that name already exists" do
    assert_equal 1, @session.queues.size
    q2 = @session.use_queue( 'bar' )
    assert_equal 2, @session.queues.size
    q3 = @session.use_queue( 'bar' )
    assert_equal 2, @session.queues.size
  end

  test "session can use an alternative schema" do
    QueueClassic::Bootstrap.setup( database_url, "qc" )
    session = QueueClassic::Session.new( database_url, "qc" )
    assert_equal 1, session.queues.size
    assert_equal 'qc, public', session.connection.search_path
    QueueClassic::Bootstrap.teardown( database_url, "qc" )
  end

  test "session creates a producer for a queue" do
    assert_equal 0, @session.producers.size
    p1 = @session.producer_for( 'foo' )
    assert_equal 1, @session.producers.size
  end

  test "session creates a consumer for a queue" do
    assert_equal 0, @session.consumers.size
    p1 = @session.consumer_for( 'foo' )
    assert_equal 1, @session.consumers.size
  end

end
