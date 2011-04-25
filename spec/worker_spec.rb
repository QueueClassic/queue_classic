require 'spec_helper'

describe QC::Worker do

  let(:array) { QC::DurableArray.new(:database => @database) }
  let(:worker) { QC::Worker.new }

  before(:all) do
    @database = database_name
    QC::Queue.instance.setup :data_store => array
    pg_clean_database(@database)
  end

  it "should work on a job" do
    QC.enqueue "Hash.new", {}
    lambda do
      worker.work
    end.should change(QC, :queue_length).by(-1)
  end
end

