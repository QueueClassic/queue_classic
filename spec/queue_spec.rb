require 'spec_helper'

describe QC::Queue do

  describe "api" do
    let(:queue) { QC::Queue.setup }

    it "should take a string" do
      queue.enqueue "job"
      queue.dequeue.should eql("job")
    end
  end

end
