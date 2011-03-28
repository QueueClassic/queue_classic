module DatabaseHelpers

  def clean_database
    drop_table
    create_table
    load_functions
    disconnect
  end

  def create_database
    postgres.exec "CREATE DATABASE #{database_name}"
  end

  def drop_database
    postgres.exec "DROP DATABASE IF EXISTS #{database_name}"
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

  def load_functions
    jobs_db.exec(<<-END
      CREATE OR REPLACE FUNCTION lock_head() RETURNS jobs AS $$
        UPDATE jobs SET locked_at = (CURRENT_TIMESTAMP)
          WHERE id = (
            SELECT id FROM jobs
            WHERE locked_at IS NULL
            ORDER BY id ASC LIMIT 1
          )
          RETURNING *;
        $$ LANGUAGE SQL;
    END
    )
  end

  def drop_table
    jobs_db.exec("DROP TABLE IF EXISTS jobs CASCADE")
  end

  def disconnect
    jobs_db.finish
    postgres.finish
  end

  def jobs_db
    connection
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

  def connection
    @connection ||= PGconn.connect(
      :dbname   => db_params.path.gsub("/",""),
      :user     => db_params.user,
      :password => db_params.password,
      :host     => db_params.host
    )
  end

end
