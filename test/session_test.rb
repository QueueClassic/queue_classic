require 'helper'
context 'SessionTest' do
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
    assert 1, queues.size
    assert 'default', queues.first.name
  end

  test "session can create a queue if it doesn't exist" do
    queues = @session.queues
    assert 1, queues.size
    q2 = @session.use_queue( 'foo' )
    assert 'foo', q2.name

    queues = @session.queues
    assert 2, queues.size
  end

  test "session does not create a new queue if one by that name already exists" do
    assert 1, @session.queues.size
    q2 = @session.use_queue( 'bar' )
    assert 2, @session.queues.size
    q3 = @session.use_queue( 'bar' )
    assert 2, @session.queues.size
  end

  test "session can use an alternative schema" do
    QueueClassic::Bootstrap.setup( database_url, "qc" )
    session = QueueClassic::Session.new( database_url, "qc" )
    assert 1, session.queues.size
    QueueClassic::Bootstrap.teardown( database_url, "qc" )
  end


end
