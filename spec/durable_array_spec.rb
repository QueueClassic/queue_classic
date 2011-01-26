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
          array.head.value.should == item
        end
      end
      context "when there are 2 items in the database" do
        it "should return the first item" do
          array << "one"
          array << "two"
          array.head.value.should == "one"
        end
      end
    end
    describe "#tail" do
      let(:array) { QC::DurableArray.new(:dbname => dbname) }
      context "when there is 1 item in the database" do
        it "should return that item" do
          array << "only one"
          array.tail.value.should == "only one"
        end
      end
      context "when there are 2 items in the database" do
        it "should return the last item inserted" do
          array << "first"
          array << "last"
          array.tail.value.should == "last"
        end
      end
    end
    describe "[]" do
      let(:array) { QC::DurableArray.new(:dbname => dbname) }
      it "should use the index to get the element" do
        array << "first"
        array << "second"
        array << "third"
        array[0].value.should == "first"
        array[1].value.should == "second"
        array[2].value.should == "third"
      end
    end
    describe "#delete" do
      let(:array) { QC::DurableArray.new(:dbname => dbname) }
      it "should delete an item" do
        array << "one"
        array[0].value.should == "one"
        array.delete(array[0])
        array[0].should be_nil
      end
    end
    describe "#each" do
      let(:array) { QC::DurableArray.new(:dbname => dbname) }
      it "should yield the value for each item" do
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
