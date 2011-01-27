require 'spec_helper'

describe QC::DurableArray do
  before(:each) { clean_database }
  let(:dbname)    {"queue_classic_test"}
  let(:job_hash)  {{"job" => "one"}}

  describe "JSON" do
    let(:array) { QC::DurableArray.new(:dbname => dbname) }
    it "should accept a hash" do
      array << {"test" => "ok"}
      array.head.details.should == {"test" => "ok"}
    end
  end

  describe "low level methods" do

    describe "#count" do
      let(:array) { QC::DurableArray.new(:dbname => dbname) }
      context "when there is 1 job in the array" do
        it "should return 1" do
          array << job_hash
          array.count.should == 1
          array << job_hash
          array.count.should == 2
        end
      end
    end
    describe "#lock" do
      let(:array) { QC::DurableArray.new(:dbname => dbname) }

      it "should set the locked_at column" do
        array << job_hash
        job = array.first

        array.lock(job)
        array.find(job).locked_at.should_not be_nil
      end
    end

    describe "#head" do
      let(:array) { QC::DurableArray.new(:dbname => dbname) }
      context "when there is 1 jobs in the database" do
        it "should return that job" do
          job = {"job" => "one"}
          array << job
          array.head.details.should == job
        end
      end
      context "when there are 2 jobs in the database" do
        it "should return the first job" do
          array << {"job" => "one"}
          array << {"job" => "two"}
          array.head.details.should == {"job" => "one"}
        end
      end
    end
    describe "#tail" do
      let(:array) { QC::DurableArray.new(:dbname => dbname) }
      context "when there is 1 job in the database" do
        it "should return that job" do
          array <<  {"job" => "one"}
          array.tail.details.should == {"job" => "one"}
        end
      end
      context "when there are 2 jobs in the database" do
        it "should return the last job inserted" do
          array << {"job" => "one"}
          array << {"job" => "two"}
          array.tail.details.should == {"job" => "two"}
        end
      end
    end
    describe "[]" do
      let(:array) { QC::DurableArray.new(:dbname => dbname) }
      it "should use the index to get the element" do
        array << {"job" => "one"  }
        array << {"job" => "two"  }
        array << {"job" => "three"}
        array[0].details.should == {"job" => "one"  }
        array[1].details.should == {"job" => "two"  }
        array[2].details.should == {"job" => "three"}
      end
    end
    describe "#delete" do
      let(:array)   { QC::DurableArray.new(:dbname => dbname) }
      it "should delete an job" do
        array << {"job" => "one"}
        array[0].details.should == {"job" => "one"}
        array.delete(array[0])
        array[0].should be_nil
      end
      it "should return the deleted job" do
        array << {"job" => "one"}
        array[0].details.should == {"job" => "one"}
        res = array.delete(array[0])
        array[0].should be_nil
        res.details.should == {"job" => "one"}
      end
    end
    describe "#each" do
      let(:array) { QC::DurableArray.new(:dbname => dbname) }
      it "should yield the details for each job" do
        array << {"job" => "one"}
        array << {"job" => "two"}
        results = []
        array.each {|v| results << v}
        results.should == [{"job" => "one"},{"job" => "two"}]
      end
      describe "including enumerable" do
        it "should give the map method" do
          array << {"job" => "1"}
          array << {"job" => "2"}
          array.map {|i| i["job"].to_i**2}.should == [1,4]
        end
      end
    end
  end
end
