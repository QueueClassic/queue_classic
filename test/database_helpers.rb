module DatabaseHelpers

  def init_db(table_name=nil)
    database  = QC::Database.new(table_name)
    database.silence_warnings
    database.init_db
    database.disconnect
    true
  end

  def create_database
    postgres.exec "CREATE DATABASE #{database_name}"
  end

  def drop_database
    postgres.exec "DROP DATABASE IF EXISTS #{database_name}"
  end

  def disconnect
    postgres.finish
  end

  def postgres
    @postgres ||= PGconn.connect(:dbname => 'postgres')
    @postgres.exec("SET client_min_messages TO 'warning'")
    @postgres
  end

  def database_name
    db_params.path.gsub("/","")
  end

  def db_params
    URI.parse(ENV["DATABASE_URL"])
  end

end
