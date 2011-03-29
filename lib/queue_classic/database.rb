module QC
  class Database

    def initialize(url)
      @db_params = URI.parse(url)
    end

    def execute(sql)
      connection.exec(sql)
    end

    def connection
      @connection ||= PGconn.connect(
        :dbname   => @db_params.path.gsub("/",""),
        :user     => @db_params.user,
        :password => @db_params.password,
        :host     => @db_params.host
      )
    end

    def disconnect
      connection.finish
    end

    def init_db
      create_table
      load_functions
    end

    def silence_warnings
      execute("SET client_min_messages TO 'warning'")
    end

    def drop_table
      execute("DROP TABLE IF EXISTS jobs CASCADE")
    end

    def create_table
      execute(
        "CREATE TABLE jobs"    +
        "("                    +
        "id        SERIAL,"    +
        "details   text,"      +
        "locked_at timestamp"  +
        ");"
      )
      execute("CREATE INDEX jobs_id_idx ON jobs (id)")
    end

    def load_functions
      execute(<<-EOD
        CREATE OR REPLACE FUNCTION lock_head() RETURNS SETOF jobs AS $$
        DECLARE
          unlocked integer;
          job jobs%rowtype;
        BEGIN
          SELECT id INTO unlocked
            FROM jobs
            WHERE locked_at IS NULL
            ORDER BY id ASC LIMIT 1
            FOR UPDATE;
          RETURN QUERY UPDATE jobs
            SET locked_at = (CURRENT_TIMESTAMP)
            WHERE id = unlocked AND locked_at IS NULL
            RETURNING *;
        END;
        $$ LANGUAGE plpgsql;
      EOD
      )
    end

  end
end
