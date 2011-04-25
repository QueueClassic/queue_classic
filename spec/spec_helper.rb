require 'queue_classic/init'

def database_name
  "queue_classic_test"
end

def pg_clean_database(database)
  pg_jobs_db(database).exec("TRUNCATE TABLE jobs")
end

def pg_jobs_db(database)
    @jobs_db ||= PGconn.connect(:dbname => database)
    @jobs_db.exec("SET client_min_messages TO 'warning'")
    @jobs_db
  end

