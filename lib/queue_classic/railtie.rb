require 'rails/railtie'

module QC
  class Railtie < ::Rails::Railtie
    rake_tasks do
      load 'queue_classic/tasks.rb'
    end
  end
end
