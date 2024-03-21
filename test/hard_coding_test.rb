# frozen_string_literal: true

require_relative 'helper'

class HardCodingTest < Minitest::Test
  def test_for_hard_coded_table_names
    # This is a simple way to do this, but prolly there could be a better way.
    #
    # TLDR: do not hard code the table name! It should (at the moment) only appear twice. Once for setup (all the upgrade SQL is currently hardcoded...),
    #       and once for the config. If you change this test to add more hard coded table names, please reconsider.
    #
    #       Ideally, you should use the config throughout the codebase; more context @ https://github.com/QueueClassic/queue_classic/issues/346
    #
    #
    #
    assert_equal `grep queue_classic_jobs lib -R`.split("\n").sort, ['lib/queue_classic/config.rb:      @table_name ||= "queue_classic_jobs"', 'lib/queue_classic/setup.rb:      conn.execute("DROP TABLE IF EXISTS queue_classic_jobs CASCADE")'].sort
  end
end
