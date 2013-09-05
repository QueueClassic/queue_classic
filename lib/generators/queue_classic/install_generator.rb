require 'rails/generators'
require 'rails/generators/migration'
require 'active_record'

module QC
  class InstallGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    namespace "queue_classic:install"
    self.source_paths << File.join(File.dirname(__FILE__), 'templates')
    desc 'Generates (but does not run) a migration to add ' +
      'a queue_classic table.'

    def self.next_migration_number(dirname)
      next_migration_number = current_migration_number(dirname) + 1
      ActiveRecord::Migration.next_migration_number(next_migration_number)
    end

    def create_migration_file
      migration_template 'add_queue_classic.rb',
        'db/migrate/add_queue_classic.rb'
    end
  end
end
