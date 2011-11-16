__Rails Compatibility: 2.X and 3.X__

### Gemfile

```ruby

  gem 'queue_classic'

```

### Rakefile

```ruby

  require 'queue_classic'
  require 'queue_classic/tasks'

```

### config/initializers/queue_classic.rb

```ruby

  # Optional if you have this set in your shell environment or use Heroku.
  ENV["DATABASE_URL"] = "postgres://username:password@localhost/database_name"

```

### Database Migration

First, we create the table that maintains the queue (queue_classic_jobs).

```ruby

class CreateJobsTable < ActiveRecord::Migration

  def change
    create_table :queue_classic_jobs do |t|
      t.text :details
      t.timestamp :locked_at
    end
    add_index :queue_classic_jobs, :id
  end

end

```

Then, we create the functions that QC depends on.
You can either call the provided rake tasks or create/drop the functions directly.

```ruby

class AddQueueClassicFunctions < ActiveRecord::Migration

  def up
    `rake qc:load_functions`
  end

  def down
    `rake qc:remove_functions`
  end

end

```

OR...

```ruby

class AddQueueClassicFunctions < ActiveRecord::Migration

  def up
    # Note: this uses AR connection, not QC connection
    QC::Database.sql_functions.each do |function_moniker, contents|
      execute("CREATE OR REPLACE FUNCTION #{function_moniker} #{contents}")
    end
  end

  def down
    # Note: this uses AR connection, not QC connection
    QC::Database.sql_function_monikers.each do |function_moniker|
      execute "DROP FUNCTION IF EXISTS #{function_moniker} CASCADE"
    end
  end

end

```
