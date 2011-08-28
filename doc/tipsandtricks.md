# Tips & Tricks


## Dispatching new jobs to workers without new code

The other day I found myself in a position in which I needed to delete a few
thousand records. The tough part of this situation is that I needed to ensure
the ActiveRecord callbacks were made on these objects thus making a simple SQL
statement unfeasible. Also, I didn't want to wait all day to select and destroy
these objects. Queue Classic to the rescue! (no pun intended)

The API of Queue Classic enables you to quickly dispatch jobs to workers. In my
case I wanted to call `Invoice.destroy(id)` a few thousand times. I fired up a
heroku console session and executed this line:

```ruby
  Invoice.find(:all, :select => "id", :conditions => "some condition").map {|i| QC.enqueue("Invoice.destroy", i.id) }
```

With the help of 20 workers I was able to destroy all of these records
(preserving their callbacks) in a few minutes.
