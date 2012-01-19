require 'helper'
context 'SessionTest' do
  setup do
    setup_db
  end

  teardown do
    teardown_db
  end

  test "session raises an error if the schema does not exist" do
    assert_raises QueueClassic::Error do
      QueueClassic::Session.new( database_url, "qc" )
    end
  end

  test "session can use an alternative schema" do
    QueueClassic::Bootstrap.setup( database_url, "qc" )
    session = QueueClassic::Session.new( database_url, "qc" )
    #assert 1, session.queues.size
    QueueClassic::Bootstrap.teardown( database_url, "qc" )
  end

end
