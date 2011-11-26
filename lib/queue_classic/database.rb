module QC
  class Database

    @@connection = nil

    attr_reader :table_name
    attr_reader :top_boundary

    def initialize(queue_name=nil)
      log("initialized")

      @top_boundary = (ENV["QC_TOP_BOUND"] || 9).to_i
      log("top_boundary=#{@top_boundary}")

      @table_name = queue_name || "queue_classic_jobs"
      log("table_name=#{@table_name}")

      @channel_name = @table_name
      log("channel_name=#{@channel_name}")

      db_url = (ENV["QC_DATABASE_URL"] || ENV["DATABASE_URL"])
      @db_params = URI.parse(db_url)
      log("uri=#{db_url}")
    end

    def set_application_name
      execute("SET application_name = 'queue_classic'")
    end

    def notify
      log("NOTIFY")
      execute("NOTIFY #{@channel_name}")
    end

    def listen
      log("LISTEN")
      execute("LISTEN #{@channel_name}")
    end

    def unlisten
      log("UNLISTEN")
      execute("UNLISTEN #{@channel_name}")
    end

    def drain_notify
      until connection.notifies.nil?
        log("draining notifications")
      end
    end

    def wait_for_notify(t)
      log("waiting for notify timeout=#{t}")
      connection.wait_for_notify(t) {|event, pid, msg| log("received notification #{event}")}
      log("done waiting for notify")
    end

    def execute(sql)
      log("executing=#{sql}")
      begin
        connection.exec(sql)
      rescue PGError => e
        log("execute exception=#{e.inspect}")
      end
    end

    def connection
      @@connection ||= connect
    end

    def disconnect
      connection.finish
      @@connection = nil
    end

    def connect
      log("establishing connection")
      conn = PGconn.connect(
        @db_params.host,
        @db_params.port || 5432,
        nil, '', #opts, tty
        @db_params.path.gsub("/",""), # database name
        @db_params.user,
        @db_params.password
      )
      if conn.status != PGconn::CONNECTION_OK
        log("connection error=#{conn.error}")
      end
      conn
    end

    def load_functions
      execute(<<-EOD)
        -- We are declaring the return type to be queue_classic_jobs.
        -- This is ok since I am assuming that all of the users added queues will
        -- have identical columns to queue_classic_jobs.
        -- When QC supports queues with columns other than the default, we will have to change this.

        CREATE OR REPLACE FUNCTION lock_head(tname name, top_boundary integer) RETURNS SETOF queue_classic_jobs AS $$
        DECLARE
          unlocked integer;
          relative_top integer;
          job_count integer;
        BEGIN
          -- The purpose is to release contention for the first spot in the table.
          -- The select count(*) is going to slow down dequeue performance but allow
          -- for more workers. Would love to see some optimization here...

          EXECUTE 'SELECT count(*) FROM ' ||
            '(SELECT * FROM ' || quote_ident(tname) ||
            ' LIMIT ' || quote_literal(top_boundary) || ') limited'
            INTO job_count;

          SELECT TRUNC(random() * top_boundary + 1) INTO relative_top;
          IF job_count < top_boundary THEN
            relative_top = 0;
          END IF;

          LOOP
            BEGIN
              EXECUTE 'SELECT id FROM '
                || quote_ident(tname)
                || ' WHERE locked_at IS NULL'
                || ' ORDER BY id ASC'
                || ' LIMIT 1'
                || ' OFFSET ' || quote_literal(relative_top)
                || ' FOR UPDATE NOWAIT'
              INTO unlocked;
              EXIT;
            EXCEPTION
              WHEN lock_not_available THEN
                -- do nothing. loop again and hope we get a lock
            END;
          END LOOP;

          RETURN QUERY EXECUTE 'UPDATE '
            || quote_ident(tname)
            || ' SET locked_at = (CURRENT_TIMESTAMP)'
            || ' WHERE id = $1'
            || ' AND locked_at is NULL'
            || ' RETURNING *'
          USING unlocked;

          RETURN;
        END;
        $$ LANGUAGE plpgsql;

        CREATE OR REPLACE FUNCTION lock_head(tname varchar) RETURNS SETOF queue_classic_jobs AS $$
        BEGIN
          RETURN QUERY EXECUTE 'SELECT * FROM lock_head($1,10)' USING tname;
        END;
        $$ LANGUAGE plpgsql;
     EOD
    end

    def log(msg)
      Logger.puts(["database", msg].join(" "))
    end

  end
end
