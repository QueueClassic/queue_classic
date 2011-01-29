$: << File.expand_path("lib")
$: << File.expand_path("test")

require 'queue_classic'
require 'database_helpers'

require 'minitest/unit'
MiniTest::Unit.autorun
