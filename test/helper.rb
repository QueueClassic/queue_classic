require 'queue_classic'
require 'minitest/autorun'

module DatabaseHelpers
  def database_url
    'postgres:///queue_classic_test'
  end

  def setup_db
    QueueClassic::Bootstrap.setup( database_url )
  end

  def teardown_db
    QueueClassic::Bootstrap.teardown( database_url )
  end
end

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
