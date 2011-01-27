require 'spec_helper'

describe QC::Queue do
  before { clean_database }
  let(:dbname) {"queue_classic_test"}
  let(:array)  { QC::DurableArray.new(:dbname => dbname) }
  let(:queue)  { QC::Queue.setup(:data_store => array) }

  describe ".dequeue" do
    it "should lock the first job in the array" do
      queue.enqueue "Notifier.send", {}
      queue.dequeue
      array.first.locked_at.should_not be_nil
    end
  end
end
