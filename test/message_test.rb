require 'helper'

context 'Message' do
  setup do
    @args = {
      'id'          => '42',
      'payload'     => 'a message payload',
      'ready_at'    => '1327123522.48697',
      'reserved_at' => '1327124925.83834',
      'reserved_by' => 'consumer-42',
      'reserved_ip' => '192.168.1.1'
    }
    @msg = QueueClassic::Message.new( @args )
  end

  test 'the id is an integer' do
    assert_equal 42, @msg.id
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

  test 'reserved_by is accessible' do
    assert_equal 'consumer-42', @msg.reserved_by
  end

  test 'message can be not finalized' do
    refute @msg.finalized?
    assert_nil @msg.finalized_at
  end

  test 'message can be finalized' do
    @args['finalized_at'] = '1327125012.33224'
    msg = QueueClassic::Message.new( @args )
    assert_equal 2012, msg.finalized_at.year
    assert msg.finalized?
  end

  test 'a mesasge can be reserved' do
    assert @msg.reserved?
  end

  test 'a message can be ready' do
    @args['reserved_at'] = nil
    msg = QueueClassic::Message.new( @args )
    assert msg.ready?
  end

  test 'reserved_ip is available' do
    assert_equal '192.168.1.1', @msg.reserved_ip
  end

  test 'reserved_ip is localhost if the value is nil' do
    @args['reserved_ip'] = nil
    msg = QueueClassic::Message.new( @args )
    assert_equal '127.0.0.1', msg.reserved_ip
  end

  test 'the finalized note can be nil' do
    assert_nil @msg.finalized_note
  end

  test 'the finalized note can hava a value' do
    @args['finalized_at'] = '1327125012.33224'
    @args['finalized_note'] = 'I am done!'
    msg = QueueClassic::Message.new( @args )
    assert_equal 'I am done!', msg.finalized_note
  end

  test 'an exception is raised if a message is in an unknown state' do
    assert_raises QueueClassic::Error do
      @args['reserved_at'] = nil
      @args['ready_at'] = nil
      msg = QueueClassic::Message.new( @args )
      msg.state
    end
  end
end
