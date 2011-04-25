require 'spec_helper'

describe QC do

  it "should enqueue a job" do
    lambda do
      QC.enqueue "Notifier send", {}
    end.should change(QC, :queue_length).by(1)
  end
end

