require 'spec_helper'

describe QC::Queue do

  describe "api" do
    before do
      @queue = QC::Queue.setup
    end

    it "should take a string" do
      @queue.enqueue "job"
      @queue.dequeue.should eql("job")
    end

    it "should take a lambda" do
      @queue.enqueue lambda {|n| sleep(n); return "slept for #{n} seconds" }
      @queue.dequeue.call(1).should eql("slept for 1 seconds")
    end

  end

end
