require 'spec_helper'

describe QC::DurableArray do
  before(:each) { clean_database }
  let(:dbname) {"queue_classic_test"}
  describe "low level methods" do
    describe "#head" do
      let(:array) { QC::DurableArray.new(:dbname => dbname) }
      context "when there is 1 jobs in the database" do
        it "should return that job" do
          job = "string"
          array << job
          array.head.details.should == job
        end
      end
      context "when there are 2 jobs in the database" do
        it "should return the first job" do
          array << "one"
          array << "two"
          array.head.details.should == "one"
        end
      end
    end
    describe "#tail" do
      let(:array) { QC::DurableArray.new(:dbname => dbname) }
      context "when there is 1 job in the database" do
        it "should return that job" do
          array << "only one"
          array.tail.details.should == "only one"
        end
      end
      context "when there are 2 jobs in the database" do
        it "should return the last job inserted" do
          array << "first"
          array << "last"
          array.tail.details.should == "last"
        end
      end
    end
    describe "[]" do
      let(:array) { QC::DurableArray.new(:dbname => dbname) }
      it "should use the index to get the element" do
        array << "first"
        array << "second"
        array << "third"
        array[0].details.should == "first"
        array[1].details.should == "second"
        array[2].details.should == "third"
      end
    end
    describe "#delete" do
      let(:array) { QC::DurableArray.new(:dbname => dbname) }
      it "should delete an job" do
        array << "one"
        array[0].details.should == "one"
        array.delete(array[0])
        array[0].should be_nil
      end
    end
    describe "#each" do
      let(:array) { QC::DurableArray.new(:dbname => dbname) }
      it "should yield the details for each job" do
        array << "one"
        array << "two"
        results = []
        array.each {|v| results << v}
        results.should == ["one","two"]
      end
      describe "including enumerable" do
        it "should give the map method" do
          array << 1
          array << 2
          array.map {|i| i.to_i**2}.should == [1,4]
        end
      end
    end
  end
end
