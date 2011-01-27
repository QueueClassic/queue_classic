require 'spec_helper'

class Notifier
  @@delivered = false
  def self.delivered
    @@delivered
  end
  def self.deliver(args={})
    @@delivered = true
  end
end

describe QC::Worker do
  describe "#run" do
    before { clean_database }

    it "should work a job" do
      QC.enqueue "Notifier.deliver", :from => "me", :to => "you"

      Notifier.delivered.should be_false
      worker = QC::Worker.new
      worker.run
      Notifier.delivered.should be_true
    end

  end
end
