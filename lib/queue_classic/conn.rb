module QC
  module Conn
    extend self

    def execute(stmt, *params)
      log("executing #{stmt.inspect}, #{params.inspect}")
      begin
        params = nil if params.empty?
        connection.exec(stmt, params)
      rescue PGError => e
        log("execute exception=#{e.inspect}")
        raise
      end
    end

    def notify(chan)
      log("NOTIFY")
      execute("NOTIFY #{chan}")
    end

    def listen(chan)
      log("LISTEN")
      execute("LISTEN #{chan}")
    end

    def unlisten(chan)
      log("UNLISTEN")
      execute("UNLISTEN #{chan}")
    end

    def drain_notify
      until connection.notifies.nil?
        log("draining notifications")
      end
    end

    def wait_for_notify(t)
      log("waiting for notify timeout=#{t}")
      connection.wait_for_notify(t) do |event, pid, msg|
        log("received notification #{event}")
      end
      log("done waiting for notify")
    end

    def transaction
      begin
        execute("BEGIN")
        yield
        execute("COMMIT")
      rescue Exception
        execute("ROLLBACK")
        raise
      end
    end

    def transaction_idle?
      connection.transaction_status == PGconn::PQTRANS_IDLE
    end

    def connection
      @connection ||= connect
    end

    def disconnect
      connection.finish
      @connection = nil
    end

    def connect
      log("establishing connection")
      conn = PGconn.connect(
        db_url.host,
        db_url.port || 5432,
        nil, '', #opts, tty
        db_url.path.gsub("/",""), # database name
        db_url.user,
        db_url.password
      )
      if conn.status != PGconn::CONNECTION_OK
        log("connection error=#{conn.error}")
      end
      conn
    end

    def db_url
      URI.parse(ENV["QC_DATABASE_URL"] || ENV["DATABASE_URL"])
    end

    def log(msg)
      Log.info(msg)
    end

  end
end
