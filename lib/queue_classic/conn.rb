require 'thread'

module QC
  module Conn
    extend self
    @exec_mutex = Mutex.new

    def execute(stmt, *params)
      @exec_mutex.synchronize do
        log(:at => "exec_sql", :sql => stmt.inspect)
        begin
          params = nil if params.empty?
          r = connection.exec(stmt, params)
          result = []
          r.each {|t| result << t}
          result.length > 1 ? result : result.pop
        rescue PGError => e
          log(:error => e.inspect)
          disconnect
          raise
        end
      end
    end

    def notify(chan)
      log(:at => "NOTIFY")
      execute('NOTIFY "' + chan + '"') #quotes matter
    end

    def listen(chan)
      log(:at => "LISTEN")
      execute('LISTEN "' + chan + '"') #quotes matter
    end

    def unlisten(chan)
      log(:at => "UNLISTEN")
      execute('UNLISTEN "' + chan + '"') #quotes matter
    end

    def drain_notify
      until connection.notifies.nil?
        log(:at => "drain_notifications")
      end
    end

    def wait_for_notify(t)
      connection.wait_for_notify(t) do |event, pid, msg|
        log(:at => "received_notification")
      end
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

    def connection=(connection)
      unless connection.instance_of? PG::Connection
        c = connection.class
        err = "connection must be an instance of PG::Connection, but was #{c}"
        raise(ArgumentError, err)
      end
      @connection = connection
    end

    def disconnect
      begin connection.finish
      ensure @connection = nil
      end
    end

    def connect
      log(:at => "establish_conn")
      conn = PGconn.connect(
        db_url.host.gsub(/%2F/i, '/'), # host or percent-encoded socket path
        db_url.port || 5432,
        nil, '', #opts, tty
        db_url.path.gsub("/",""), # database name
        db_url.user,
        db_url.password
      )
      if conn.status != PGconn::CONNECTION_OK
        log(:error => conn.error)
      end
      conn
    end

    def db_url
      return @db_url if @db_url
      url = ENV["QC_DATABASE_URL"] ||
            ENV["DATABASE_URL"]    ||
            raise(ArgumentError, "missing QC_DATABASE_URL or DATABASE_URL")
      @db_url = URI.parse(url)
    end

    def log(msg)
      QC.log(msg)
    end

  end
end
