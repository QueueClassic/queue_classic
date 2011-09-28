# Tips & Tricks


## Dispatching new jobs to workers without new code

The other day I found myself in a position in which I needed to delete a few
thousand records. The tough part of this situation is that I needed to ensure
the ActiveRecord callbacks were made on these objects thus making a simple SQL
statement unfeasible. Also, I didn't want to wait all day to select and destroy
these objects. queue_classic to the rescue! (no pun intended)

The API of queue_classic enables you to quickly dispatch jobs to workers. In my
case I wanted to call `Invoice.destroy(id)` a few thousand times. I fired up a
heroku console session and executed this line:

```ruby
  Invoice.find(:all, :select => "id", :conditions => "some condition").map {|i| QC.enqueue("Invoice.destroy", i.id) }
```

With the help of 20 workers I was able to destroy all of these records
(preserving their callbacks) in a few minutes.

## Enqueueing batches of jobs

I have seen several cases where the application will enqueue jobs in batches. For instance, you may be sending
1,000 emails out. In this case, it would be foolish to do 1,000 individual transaction. Instead, you want to open 
a new transaction, enqueue all of your jobs and then commit the transaction. This will save tons of time in the 
database.

To achieve this we will create a helper method:

```ruby

def qc_txn
  begin
    QC.database.execute("BEGIN")
    yield
    QC.database.execute("COMMIT")
  rescue Exception
    QC.database.execute("ROLLBACK")
    raise
  end
end
```

Now in your application code you can do something like:

```ruby
qc_txn do
  Account.all.each do |act|
    QC.enqueue("Emailer.send_notice", act.id)
  end
end
```