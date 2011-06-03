__Rails Compatibility: 2.X and 3.X__

### Gemfile

```ruby

  gem "queue_classic"

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

```ruby

class CreateJobsTable < ActiveRecord::Migration

  def self.up
    create_table :queue_classic_jobs do |t|
      t.text :details
      t.timestamp :locked_at
    end
    add_index :queue_classic_jobs, :id
  end

  def self.down
    drop_table :queue_classic_jobs
  end

end

```

### Load PL/pgSQL Functions

```bash

  rake qc:load_functions

```
