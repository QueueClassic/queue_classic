require 'spec_helper'

describe QC::Queue do

  describe ".setup" do
    context "when data_store does not respond to <<" do
      it "should raise argument error" do
        lambda { QC::Queue.setup(:data_store => {}) }.should raise_error
      end
    end
    context "when data_store responds to <<" do
      it "should not raise an error" do
        lambda { QC::Queue.setup(:data_store => "") }.should_not raise_error
      end
    end
  end

end
