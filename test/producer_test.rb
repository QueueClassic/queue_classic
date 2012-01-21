require 'helper'

context 'Producer' do
  setup do
    setup_db
    @session = QueueClassic::Session.new( database_url )
  end

  teardown do
    teardown_db
  end

  test 'producer can add an item to the queue' do
    p = @session.producer_for('foo')
    assert 0, p.queue.size
    p.put( "a message")
    assert 1, p.queue.size
  end

end
