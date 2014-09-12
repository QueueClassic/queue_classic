require File.expand_path("../../helper.rb", __FILE__)

class QueueClassicRailsConnectionTest < QCTest
  def test_uses_active_record_connection_if_exists
    # This is unimplmented. I am not very used to work minitest, what I want
    # to achieve is something not too hacky that would be the equivalent of:
    #   expect(ActiveRecord::Base.connection).to receive(:raw_connection)

    raise "we need something that works here..."
  end

  def test_does_not_use_active_record_connection_if_doesnt_exists
    raise "unimplemented"
  end
