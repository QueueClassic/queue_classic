require File.expand_path("../helper.rb", __FILE__)

context "Job" do

  test "initialize takes details as JSON" do
    job = QC::Job.new(
      "id" => 1,
      "details" => "{\"arg\":1}",
      "locked_at" => nil
    )
    assert_equal({"arg" => 1}, job.details)
  end

  test "signature returns the class and method" do
    job = QC::Job.new(
      "id" => 1,
      "details" => {:job => "Class.method", :params => []}.to_json,
      "locked_at" => nil
    )
    assert_equal "Class.method", job.signature
  end

  test "method returns the class method" do
    job = QC::Job.new(
      "id" => 1,
      "details" => {:job => "Class.method", :params => []}.to_json,
      "locked_at" => nil
    )
    assert_equal "method", job.method
  end

  test "klass returns the class" do
    class WhoHa; end
    job = QC::Job.new(
      "id" => 1,
      "details" => {:job => "WhoHa.method", :params => []}.to_json,
      "locked_at" => nil
    )
    assert_equal WhoHa, job.klass
  end

  test "klass returns the class when scoped to module" do
    module Mod
      class K
      end
    end

    job = QC::Job.new(
      "id" => 1,
      "details" => {:job => "Mod::K.method", :params => []}.to_json,
      "locked_at" => nil
    )
    assert_equal Mod::K, job.klass
  end

  test "params returns empty array when nil" do
     job = QC::Job.new(
      "id" => 1,
      "details" => {:job => "Mod::K.method", :params => nil}.to_json,
      "locked_at" => nil
    )
    assert_equal [], job.params
 end

  test "params returns 1 items when there is 1 param" do
    job = QC::Job.new(
      "id" => 1,
      "details" => {:job => "Mod::K.method", :params => ["arg"]}.to_json,
      "locked_at" => nil
    )
    assert_equal "arg", job.params
  end

  test "params retuns many items when there are many params" do
    job = QC::Job.new(
      "id" => 1,
      "details" => {:job => "Mod::K.method", :params => ["arg","arg"]}.to_json,
      "locked_at" => nil
    )
    assert_equal ["arg","arg"], job.params
  end
end
