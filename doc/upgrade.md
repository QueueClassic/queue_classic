### 0.2.X to 0.3.X

* Deprecated QC.queue_length in favor of QC.length
* Locking functions need to be loaded into database via `$ rake qc:load_functions`


Also, the default queue is no longer named jobs,
it is named queue_classic_jobs. Renaming the table is the only change that needs to be made.

```bash
  $ psql your_database
  your_database=# ALTER TABLE jobs RENAME TO queue_classic_jobs;
```

Or if you are using Rails' Migrations:

```ruby
class RenameJobsTable < ActiveRecord::Migration

  def self.up
    rename_table :jobs, :queue_classic_jobs
    remove_index :jobs, :id
    add_index :queue_classic_jobs, :id
  end

  def self.down
    rename_table :queue_classic_jobs, :jobs
    remove_index :queue_classic_jobs, :id
    add_index :jobs, :id
  end

end
```
