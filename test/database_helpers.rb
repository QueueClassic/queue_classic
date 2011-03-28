module DatabaseHelpers

  def init_db
    database  = QC::Database.new(ENV["DATABASE_URL"])
    database.silence_warnings
    database.drop_table
    database.init_db
    database
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
