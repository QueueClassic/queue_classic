# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/migration'
require 'active_record'

module QC
  # Install generator to create migration files for rails
  class InstallGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    namespace 'queue_classic:install'
    source_paths << File.join(File.dirname(__FILE__), 'templates')
    desc 'Generates (but does not run) a migration to add a queue_classic table.'

    def self.next_migration_number(dirname)
      next_migration_number = current_migration_number(dirname) + 1
      ActiveRecord::Migration.next_migration_number(next_migration_number)
    end

    def create_migration_file
      migration_template 'add_queue_classic.rb', 'db/migrate/add_queue_classic.rb' if self.class.migration_exists?('db/migrate', 'add_queue_classic').nil?
      migration_template 'update_queue_classic_3_0_0.rb', 'db/migrate/update_queue_classic_3_0_0.rb' if self.class.migration_exists?('db/migrate', 'update_queue_classic_3_0_0').nil?
      migration_template 'update_queue_classic_3_0_2.rb', 'db/migrate/update_queue_classic_3_0_2.rb' if self.class.migration_exists?('db/migrate', 'update_queue_classic_3_0_2').nil?
      migration_template 'update_queue_classic_3_1_0.rb', 'db/migrate/update_queue_classic_3_1_0.rb' if self.class.migration_exists?('db/migrate', 'update_queue_classic_3_1_0').nil?
      migration_template 'update_queue_classic_4_0_0.rb', 'db/migrate/update_queue_classic_4_0_0.rb' if self.class.migration_exists?('db/migrate', 'update_queue_classic_4_0_0').nil?
    end
  end
end
