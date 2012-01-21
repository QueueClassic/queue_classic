require 'helper'

context 'Message' do
  setup do
    @args = {
      'id'          => '42',
      'queue'       => ::QueueClassic::Queue.new( nil, 'foo'),
      'payload'     => 'a message payload',
      'ready_at'    => '1327123522.48697',
      'reserved_at' => '1327124925.83834',
      'reserved_by' => 'consumer-42',
      'reserved_ip' => '127.0.0.1'
    }
    @msg = QueueClassic::Message.new( @args )
  end

  test 'the id is an integer' do
    assert_equal 42, @msg.id
  end

  test 'the queue is a queue object' do
    assert_equal 'foo', @msg.queue.name
  end

  test 'the payload is accessible' do
    assert_equal 'a message payload', @msg.payload
  end

  test 'reserved_at is a Time' do
    assert_kind_of Time, @msg.reserved_at
    assert_equal 2012, @msg.reserved_at.year
  end

  test 'ready_at is a Time' do
    assert_kind_of Time, @msg.ready_at
    assert_equal 2012, @msg.ready_at.year
  end

end
