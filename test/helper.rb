$: << File.expand_path("lib")
$: << File.expand_path("test")

require 'queue_classic'
require 'database_helpers'

require 'minitest/unit'
MiniTest::Unit.autorun

def context(*args, &block)
  return super unless (name = args.first) && block
  klass = Class.new(MiniTest::Unit::TestCase) do
    def self.test(name, &block)
      define_method("test_#{name.gsub(/\W/,'_')}", &block) if block
    end
    def self.xtest(*args) end
    def self.setup(&block) define_method(:setup, &block) end
    def self.teardown(&block) define_method(:teardown, &block) end
  end
  (class << klass; self end).send(:define_method, :name) { name.gsub(/\W/,'_') }

  klass.send :include, DatabaseHelpers
  klass.class_eval &block
end
