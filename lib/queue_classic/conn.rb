require 'thread'
require 'uri'
require 'pg'

module QC
  class Conn
    @conn_mutex = Mutex.new

    def initialize(connection = nil)
      @exec_mutex = Mutex.new
      @connection = connection || connect
    end

    def execute(stmt, *params)
      @exec_mutex.synchronize do
        log(:at => "exec_sql", :sql => stmt.inspect)
        begin
          params = nil if params.empty?
          r = @connection.exec(stmt, params)
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

    def wait(chan)
      execute('LISTEN "' + chan + '"')
      wait_for_notify(WAIT_TIME)
      execute('UNLISTEN "' + chan + '"')
      drain_notify
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
      @connection.transaction_status == PGconn::PQTRANS_IDLE
    end

    def self.connection
      @connection ||= @conn_mutex.synchronize do
         new
      end
    end

    def self.method_missing(method, *args, &block)
      connection.send(method, *args, &block)
    end

    def self.cas_connection
      @conn_mutex.synchronize do
        @cas_connection ||= connection.dup
      end
    end

    def self.connection=(connection)
      unless connection.is_a? PG::Connection
        c = connection.class
        err = "connection must be an instance of PG::Connection, but was #{c}"
        raise(ArgumentError, err)
      end
      @conn_mutex.synchronize do
        @connection = new(connection)
      end
    end

    def disconnect
      begin @connection.finish
      ensure @connection = nil
      end
    end

    def dup
      self.class.new PGconn.connect(
       @connection.host,
       @connection.port,
       nil, 
       '', 
       @connection.db, 
       @connection.user,
       @connection.pass
      )
    end

    def connect
      log(:at => "establish_conn")
      conn = PGconn.connect(*normalize_db_url(db_url))
      if conn.status != PGconn::CONNECTION_OK
        log(:error => conn.error)
      end
      conn.exec("SET application_name = '#{QC::APP_NAME}'")
      conn
    end

    def normalize_db_url(url)
      host = url.host
      host = host.gsub(/%2F/i, '/') if host

      [
       host, # host or percent-encoded socket path
       url.port || 5432,
       nil, '', #opts, tty
       url.path.gsub("/",""), # database name
       url.user,
       url.password
      ]
    end

    def db_url
      return @db_url if @db_url
      url = ENV["QC_DATABASE_URL"] ||
            ENV["DATABASE_URL"]    ||
            raise(ArgumentError, "missing QC_DATABASE_URL or DATABASE_URL")
      @db_url = URI.parse(url)
    end

    private

    def log(msg)
      QC.log(msg)
    end

    def wait_for_notify(t)
      Array.new.tap do |msgs|
        @connection.wait_for_notify(t) {|event, pid, msg| msgs << msg}
      end
    end

    def drain_notify
      until @connection.notifies.nil?
        log(:at => "drain_notifications")
      end
    end

  end
end
