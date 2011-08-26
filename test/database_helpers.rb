module DatabaseHelpers

  def init_db(table_name="queue_classic_jobs")
    database = QC::Database.new(table_name)
    database.execute("SET client_min_messages TO 'warning'")
    database.execute("DROP TABLE IF EXISTS #{table_name} CASCADE")
    database.execute("CREATE TABLE #{table_name} (id serial, details text, locked_at timestamp)")
    database.load_functions
    database.disconnect
    database
  end

end
