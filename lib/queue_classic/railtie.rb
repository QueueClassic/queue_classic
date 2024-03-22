# frozen_string_literal: true

require 'rails/railtie'

module QC
  # Railtie integrates queue_classic with Rails applications.
  class Railtie < ::Rails::Railtie
    rake_tasks do
      load 'queue_classic/tasks.rb'
    end
  end
end
