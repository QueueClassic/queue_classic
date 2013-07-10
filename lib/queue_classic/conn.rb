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
    end

    def execute(stmt, *params)
      QC.log(:measure => "conn.exec", :sql => stmt.inspect) do
        begin
          params = nil if params.empty?
          r = @c.exec(stmt, params)
          result = []
          r.each {|t| result << t}
          result.length > 1 ? result : result.pop
        rescue PGError => e
          QC.log(:error => e.inspect)
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

    def disconnect
      begin @c.finish
      ensure @c = nil
      end
    end

    private

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
