require 'spec_helper'

describe QC::Queue do

  before(:each) do
    QC::Queue.instance.setup :data_store => []
    @queue = QC::Queue.instance
  end

  it "should be singleton" do
    QC::Queue.should be_equal(QC::Queue.instance.class)
  end

  it "should initialize a queue data store" do
    [].should == QC::Queue.instance.instance_variable_get(:@data)
  end

  it "should the right length" do
    lambda do
      @queue.enqueue "job", "params"
    end.should change(QC::Queue.instance, :length).by(1)
  end

end

