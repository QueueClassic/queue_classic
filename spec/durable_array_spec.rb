require 'spec_helper'

describe QC::DurableArray do
  before(:each) { clean_database }
  let(:dbname) {"queue_classic_test"}

  describe "low level methods" do
    describe "#head" do
      let(:array) { QC::DurableArray.new(:dbname => dbname) }
      context "when there is 1 items in the database" do
        it "should return that item" do
          item = "string"
          array << item
          array.head.should == item
        end
      end
      context "when there are 2 items in the database" do
        it "should return the first item" do
          array << "one"
          array << "two"
          array.head.should == "one"
        end
      end
    end
    describe "#tail" do
      let(:array) { QC::DurableArray.new(:dbname => dbname) }
      context "when there is 1 item in the database" do
        it "should return that item" do
          array << "only one"
          array.tail.should == "only one"
        end
      end
      context "when there are 2 items in the database" do
        it "should return the last item inserted" do
          array << "first"
          array << "last"
          array.tail.should == "last"
        end
      end
    end
    describe "#each" do
      let(:array) { QC::DurableArray.new(:dbname => dbname) }
      it "should yield the value for each item" do
        array << "one"
        array << "two"
        results = []
        array.each {|v| results << v }
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
