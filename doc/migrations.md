# Example migrations

## Sequel


### Jobs Table
```ruby
Sequel.migration do
  up do
    create_table :queue_classic_jobs do 
      primary_key :id
      String :details
      Time   :locked_at
    end
  end

  down do
    drop_table :queue_classic_jobs
  end
end
```

### Loading the Functions
```ruby
def load_qc
  require 'queue_classic'
  ENV['QC_DATABASE_URL'] = self.uri
end

Sequel.migration do
  up do
    load_qc
    QC::Database.new.load_functions
  end

  down do
    load_qc
    QC::Database.new.unload_functions
  end
end
```
