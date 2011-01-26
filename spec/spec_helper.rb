require File.join(File.dirname(__FILE__), '..', 'lib', 'queue_classic')

RSpec.configure do |c|
end

def clean_database
  drop_table
  create_table
end

def create_database
  execute "CREATE DATABASE queue_classic_test"
end

def drop_database
  execute "DROP DATABASE IF EXISTS queue_classic_test"
end

def create_table
  test_db.exec(
    "CREATE TABLE jobs"  +
    "("                   +
    "job_id   SERIAL,"    +
    "details  text"       +
    ");"
  )
end

def drop_table
  test_db.exec("DROP TABLE jobs")
end

def test_db
  @testdb ||= PGconn.open(:dbname => 'queue_classic_test')
  @testdb.exec("SET client_min_messages TO 'warning'")
  @testdb
end

def postgres
  @postgres ||= PGconn.open(:dbname => 'postgres')
  @postgres.exec("SET client_min_messages TO 'warning'")
  @postgres
end
