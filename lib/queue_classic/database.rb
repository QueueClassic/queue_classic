module QC
  class Database
    @@connection = nil

    DATABASE_URL        = (ENV["QC_DATABASE_URL"] || ENV["DATABASE_URL"])
    MAX_TOP_BOUND       = (ENV["QC_TOP_BOUND"] || 9).to_i
    NOTIFY_TIMEOUT      = (ENV["QC_NOTIFY_TIMEOUT"] || 10).to_i
    DEFAULT_QUEUE_NAME  = "queue_classic_jobs"

    def self.create_queue(name)
      db = new(name)
      db.create_table
      db.disconnect
      true
    end

    attr_reader :table_name

    def initialize(queue_name=nil)
      @top_boundry = MAX_TOP_BOUND
      @table_name = queue_name || DEFAULT_QUEUE_NAME
      @db_params = URI.parse(DATABASE_URL)
    end

    def init_db
      drop_table
      create_table
      load_functions
    end

    def listen
      execute("LISTEN queue_classic_jobs")
    end

    def unlisten
      execute("UNLISTEN queue_classic_jobs")
    end

    def wait_for_notify
      connection.wait_for_notify(NOTIFY_TIMEOUT)
    end

    def waiting_conns
      execute("SELECT * FROM pg_stat_activity WHERE datname = '#{@name}' AND waiting = 't' AND application_name = 'queue_classic'")
    end

    def all_conns
      execute("SELECT * FROM pg_stat_activity WHERE datname = '#{@name}' AND application_name = 'queue_classic'")
    end

    def execute(sql)
      connection.exec(sql)
    end

    def disconnect
      connection.finish
      @@connection = nil
    end

    def connect
      PGconn.connect(
        @db_params.host,
        @db_params.port || 5432,
        nil, '',
        @name,
        @db_params.user,
        @db_params.password
      )
    end

    def connection
      unless @@connection
        @name = @db_params.path.gsub("/","")
        @@connection = connect
      end
      @@connection
    end

    def set_application_name
      execute("SET application_name = 'queue_classic'")
    end

    def drop_table
      execute("DROP TABLE IF EXISTS #{@table_name} CASCADE")
    end

    def create_table
      execute("CREATE TABLE #{@table_name} (id serial, details text, locked_at timestamp)")
      execute("CREATE INDEX #{@table_name}_id_idx ON #{@table_name} (id)")
    end

    def load_functions
      execute(<<-EOD)
        -- We are declaring the return type to be queue_classic_jobs.
        -- This is ok since I am assuming that all of the users added queues will
        -- have identical columns to queue_classic_jobs.
        -- When QC supports queues with columns other than the default, we will have to change this.

        CREATE OR REPLACE FUNCTION lock_head(tname varchar) RETURNS SETOF queue_classic_jobs AS $$
        DECLARE
          unlocked integer;
          relative_top integer;
          job_count integer;
        BEGIN
          -- The purpose is to release contention for the first spot in the table.
          -- The select count(*) is going to slow down dequeue performance but allow
          -- for more workers. Would love to see some optimization here...

          SELECT TRUNC(random() * #{@top_boundry} + 1) INTO relative_top;
          EXECUTE 'SELECT count(*) FROM' || tname || '' INTO job_count;
          IF job_count < 10 THEN
            relative_top = 0;
          END IF;

          LOOP
            BEGIN
              EXECUTE 'SELECT id FROM '
                || tname::regclass
                || ' WHERE locked_at IS NULL'
                || ' ORDER BY id ASC'
                || ' LIMIT 1'
                || ' OFFSET ' || relative_top
                || ' FOR UPDATE NOWAIT'
              INTO unlocked;
              EXIT;
            EXCEPTION
              WHEN lock_not_available THEN
                -- do nothing. loop again and hope we get a lock
            END;
          END LOOP;

          RETURN QUERY EXECUTE 'UPDATE '
            || tname::regclass
            || ' SET locked_at = (CURRENT_TIMESTAMP)'
            || ' WHERE id = $1'
            || ' AND locked_at is NULL'
            || ' RETURNING *'
          USING unlocked;

          RETURN;
        END;
        $$ LANGUAGE plpgsql;
      EOD
    end

  end
end
