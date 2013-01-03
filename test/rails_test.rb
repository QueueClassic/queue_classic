require File.expand_path("../helper.rb", __FILE__)
require 'queue_classic/rails'

class RailsTest < QCTest

  class TestJob
    attr_reader :arguments
    def initialize(*arguments)
      @arguments = arguments
    end

    def run
      @arguments
    end
  end

  def setup
    super
    @queue = QC::Rails::Queue.new
  end

  def test_push_with_job_instance
    job = RailsTest::TestJob.new(1, 'hans')
    @queue.push(job)

    actual = QC.lock

    assert_equal('1', actual[:id])
    assert_equal('QC::Rails::Job.run', actual[:method])
    assert_equal('RailsTest::TestJob', actual[:args].first)
    assert_kind_of(String, actual[:args].last)
  end

  def test_rails_job_executes_real_job
    job = RailsTest::TestJob.new(1, 'hans')
    @queue.push(job)

    worker = QC::Worker.new("default", 1, false, false, 1)
    result = worker.work
    assert_equal([1, 'hans'], result)
  end

end
