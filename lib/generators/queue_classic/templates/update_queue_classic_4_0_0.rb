# frozen_string_literal: true

class UpdateQueueClassic400 < ActiveRecord::Migration[4.2]
  def self.up
    QC::Setup.update_to_4_0_0
  end

  def self.down
    QC::Setup.downgrade_from_4_0_0
  end
end
