require 'spec_helper'

describe QC::DurableArray do

  let(:array) { QC::DurableArray.new(:adapter => 'postgres', :database => @database) }

  before(:all) do
    @user = "pmiranda"
    @password = "1234"
    @host = "localhost"
    @database = database_name
    pg_prepare_database(@database)
    QC::Queue.instance.setup :data_store => array
  end

  after(:all) do
    array.connection.finish
  end

  before( :each ) do
    pg_clean_database(@database)
  end

  it "should decode json" do
    job = {"test" => "ok"}
    array << job
    array.first.details.should == job
  end

  it "should return the right number of rows" do
    array << {"test" => "ok"}
    array.count.should == 1
  end

  it "should return the first job" do
    job1 = {"test" => "ok"}
    job2 = {"test 2" => "ok 2"}
    array << job1
    array << job2
    array.first.details.should == job1
  end

  it "should delete the job" do
    array << {"test" => "ok"}
    job = array.first
    lambda do
      array.delete(job)
    end.should change(array, :count).by(-1)
  end

  it "should have details of the jobs" do
    job1 = {"test" => "ok"}
    job2 = {"test 2" => "ok 2"}
    array << job1
    array << job2
    jobs_details = []
    array.each { |item| jobs_details << item }
    jobs_details.should include(job1)
    jobs_details.should include(job2)
  end

  it "should have user connection information" do
    array.connection.user.should == @user
  end

  it "should have database connection information" do
    array.connection.db.should == @database
  end

  it "should have create a connection from URI" do
    array = QC::DurableArray.new(:database => "postgres://#{@user}:#{@password}@#{@host}/#{@database}")
    array.connection.host.should == @host
  end

end

