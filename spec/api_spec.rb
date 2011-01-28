require 'spec_helper'

describe QC::Api do
  before(:each) { clean_database }
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
    it "should remove the job from the jobs table" do
      QC.enqueue "Notifier.send", {"args1" => "test"}
      QC.dequeue.details.should == {"job" => "Notifier.send", "params"=>[{"args1"=>"test"}]}
    end
  end
end
