module QC
  class Database
    attr_accessor :plan

    def initialize(url,opts={})
      @db_params = URI.parse(url)
      @top_boundry = opts[:top_boundry] || 9
    end

    def init_db
      drop_table
      create_table
      load_functions
    end

    def execute(sql)
      connection.exec(sql)
    end

    def disconnect
      connection.finish
    end

    def connection
      if defined? @connection
        @connection
      else
        @name = @db_params.path.gsub("/","")
        @connection = PGconn.connect(
          :dbname   => @db_params.path.gsub("/",""),
          :user     => @db_params.user,
          :password => @db_params.password,
          :host     => @db_params.host
        )
        @connection.exec("LISTEN jobs")
        @connection
      end
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
      @plan ||= :fifo

      case @plan
      when :random_offset
        execute(<<-EOD
          CREATE OR REPLACE FUNCTION lock_head() RETURNS SETOF jobs AS $$
          DECLARE
            unlocked integer;
            relative_top integer;
            job_count integer;
            job jobs%rowtype;

          BEGIN
            SELECT TRUNC(random() * #{@top_boundry} + 1) INTO relative_top;
            SELECT count(*) from jobs INTO job_count;

            IF job_count < 10 THEN
              relative_top = 0;
            END IF;

            SELECT id INTO unlocked
              FROM jobs
              WHERE locked_at IS NULL
              ORDER BY id ASC
              LIMIT 1
              OFFSET relative_top
              FOR UPDATE NOWAIT;
            RETURN QUERY UPDATE jobs
              SET locked_at = (CURRENT_TIMESTAMP)
              WHERE id = unlocked AND locked_at IS NULL
              RETURNING *;
          END;
          $$ LANGUAGE plpgsql;
        EOD
        )
      when :fifo
        execute(<<-EOD
          CREATE OR REPLACE FUNCTION lock_head() RETURNS jobs AS $$
            UPDATE jobs SET locked_at = (CURRENT_TIMESTAMP)
              WHERE id = (
                SELECT id FROM jobs
                WHERE locked_at IS NULL
                ORDER BY id ASC LIMIT 1
              )
            RETURNING *;
          $$ LANGUAGE SQL;
        EOD
        )
      end
    end

  end
end
