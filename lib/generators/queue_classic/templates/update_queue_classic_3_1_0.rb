class UpdateQueueClassic310 < ActiveRecord::Migration
  def self.up
    QC::Setup.update_to_3_1_0
  end

  def self.down
    QC::Setup.downgrade_from_3_1_0
  end
end
