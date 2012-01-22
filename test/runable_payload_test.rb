require 'helper'

context 'RunablePayload' do
  class QueueClassic::FakeJob
    def self.perform( *args )
      "called FakeJob.perform( #{args_as_string(args)} )"
    end

    def self.other( *args )
      "called FakeJob.other( #{args_as_string(args)} )"
    end

    def self.args_as_string(args)
      args.map { |a| a.inspect }.join(", ")
    end
  end

  setup do
    @qc_json     = { "job" => "QueueClassic::FakeJob.other", "params" => [ "a", 42 ] }.to_json
    @resque_json = { "class" => "QueueClassic::FakeJob", "args" => [ "b", "foo", 42 ] }.to_json
  end

  test "has the proper klass.method(args) for a QC style payload" do
    p = ::QueueClassic::RunablePayload.new( @qc_json )
    assert_equal QueueClassic::FakeJob, p.klass
    assert_equal "other", p.method
    assert_equal [ "a", 42 ], p.args
  end

  test "has the proper klass.method(args) for a Resque style payload" do
    p = ::QueueClassic::RunablePayload.new( @resque_json )
    assert_equal QueueClassic::FakeJob, p.klass
    assert_equal "perform", p.method
    assert_equal [ "b", "foo", 42 ], p.args
  end

  test "raises an error if an unknown class is used" do
    bad_json = { "class" => "QueueClassic::BadClass", "args" => [] }.to_json
    assert_raises NameError do
      p = ::QueueClassic::RunablePayload.new( bad_json )
    end
  end

  test "raises an error if an unknown method is used" do
    bad_json = { "job" => "QueueClassic::FakeJob.boom", "params" => [] }.to_json
    assert_raises NotImplementedError do
      p = ::QueueClassic::RunablePayload.new( bad_json )
    end
  end

  test "invokes a QC style payload correctly" do
    p = ::QueueClassic::RunablePayload.new( @qc_json )
    result = p.run
    assert_equal 'called FakeJob.other( "a", 42 )', result
  end

  test "invokes a Resque style payload correctly" do
    p = ::QueueClassic::RunablePayload.new( @resque_json )
    result = p.run
    assert_equal 'called FakeJob.perform( "b", "foo", 42 )', result
  end
end
