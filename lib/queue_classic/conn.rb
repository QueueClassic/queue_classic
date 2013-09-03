require 'queue_classic/conf'
require 'thread'
require 'uri'
require 'pg'

module QC
  class Conn

    def self.connect
      QC.log(:at => "establish_conn")
      conn = PGconn.connect(*Conf.normalized_db_url)
      if conn.status != PGconn::CONNECTION_OK
        log(:error => conn.error)
      end
      if !Conf.debug?
        conn.exec("SET client_min_messages TO 'warning'")
      end
      conn.exec("SET application_name = '#{QC::APP_NAME}'")
      conn
    end

    def initialize
      @c = self.class.connect
      @max_attempts = 2
    end

    def execute(stmt, *params)
      QC.log(:measure => "conn.exec", :sql => stmt.inspect) do
        with_retry(@max_attempts) do
          params = nil if params.empty?
          r = @c.exec(stmt, params)
          result = []
          r.each {|t| result << t}
          result.length > 1 ? result : result.pop
        end
      end
    end

    def wait(chan)
      with_retry(@max_attempts) do
        execute('LISTEN "' + chan + '"')
        wait_for_notify(WAIT_TIME)
        execute('UNLISTEN "' + chan + '"')
        drain_notify
      end
    end

    def reconnect
      disconnect
      @c = self.class.connect
    end

    def disconnect
      begin @c.finish
      ensure @c = nil
      end
    end

    def abort_open_transaction
      if @c.transaction_status != PGconn::PQTRANS_IDLE
        @c.exec('ROLLBACK')
      end
    end

    private

    def with_retry(n)
      completed = false
      attempts = 0
      result = nil
      last_error = nil
      until completed || attempts == n
        attempts += 1
        begin
          result = yield
          completed = true
        rescue => e
          QC.log(:error => e.class, :at => 'conn-retry', :attempts => attempts)
          last_error = e
          reconnect
        end
      end
      completed ? result : raise(last_error)
    end

    def wait_for_notify(t)
      Array.new.tap do |msgs|
        @c.wait_for_notify(t) {|event, pid, msg| msgs << msg}
      end
    end

    def drain_notify
      until @c.notifies.nil?
        QC.log(:at => "drain_notifications")
      end
    end

  end
end
