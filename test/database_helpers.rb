module DatabaseHelpers

  def clean_database
    drop_table
    create_table
    disconnect
  end

  def create_database
    postgres.exec "CREATE DATABASE #{ENV['DATABASE_URL']}"
  end

  def drop_database
    postgres.exec "DROP DATABASE IF EXISTS #{ENV['DATABASE_URL']}"
  end

  def create_table
    jobs_db.exec(
      "CREATE TABLE jobs"    +
      "("                    +
      "id        SERIAL,"    +
      "details   text,"      +
      "locked_at timestamp without time zone" +
      ");"
    )
    jobs_db.exec("CREATE INDEX jobs_id_idx ON jobs (id)")
  end

  def drop_table
    jobs_db.exec("DROP TABLE IF EXISTS jobs")
  end

  def disconnect
    jobs_db.finish
    postgres.finish
  end

  def jobs_db
    @jobs_db ||= PGconn.connect(:dbname => ENV["DATABASE_URL"])
    @jobs_db.exec("SET client_min_messages TO 'warning'")
    @jobs_db
  end

  def postgres
    @postgres ||= PGconn.connect(:dbname => 'postgres')
    @postgres.exec("SET client_min_messages TO 'warning'")
    @postgres
  end
end
