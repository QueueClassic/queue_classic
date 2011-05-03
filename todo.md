Priority
=======

1. Decide on the best approach for lock_head() (Will we ever be done with this? No.)
2. Workers will die. Their locks will be abandoned. Perhaps we can use DB triggers to do some GC on jobs.
3. Add support for a run_at column. I think this should be a "plugin."
4. Should we support periodic jobs. Or is that what cron (clock process on Heroku) is for?

Backlog
=======

* Prepared statements for queries
* Python bindings
* Bash bindings
* A Worker implemented in C that can process UNIX exec() (see queue_cc)
