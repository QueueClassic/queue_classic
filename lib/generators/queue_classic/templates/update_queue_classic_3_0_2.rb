class UpdateQueueClassic302 < ActiveRecord::Migration
  def self.up
    QC::Setup.update_to_3_0_0
  end

  def self.down
    # This migration is fixing a bug, so we don't want to do anything here.
    # I didn't want to make it irreversible either, as it could prevent
    # rolling back other, unrelated, stuff.
  end
end
