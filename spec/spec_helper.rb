require 'queue_classic/init'

def database_name
  "queue_classic_test"
end

def pg_prepare_database(database)
  pg_clean_database(database)
end

def pg_clean_database(database)
  pg_connection(database).exec("TRUNCATE TABLE jobs")
end

def pg_connection(database)
  if @postgres && database != @postgres.db
    pg_close_connection
  end
  @postgres ||= PGconn.connect(:dbname => database)
  @postgres.exec("SET client_min_messages TO 'warning'")
  @postgres
end

def pg_close_connection
  @postgres.finish
  @postgres = nil
end

