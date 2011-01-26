require 'spec_helper'

describe QC::Api do
  describe "#enqueue" do
    it "should take a job" do
      res = QC.enqueue "Notifier.send", {}
      res.should be_true
    end
    it "should take a hash of arguments" do
      res = QC.enqueue "Notifier.send", :from => "me", :to => "you"
      res.should be_true
    end
  end
  describe "#dequeue" do
    it "should remove the job from the jobs table"
    it "should add the job to the processing table"
  end
end
