require File.join(File.dirname(__FILE__), '..', 'lib', 'queue_classic')
require File.join(File.dirname(__FILE__), 'database_helpers')

RSpec.configure do |c|
  c.include(DatabaseHelpers)
end
