# frozen_string_literal: true

require 'uri'
require 'pg'

module QC
  # This class is responsible for managing the connection to the database.
  class ConnAdapter
    def initialize(args = {})
      @active_record_connection_share = args[:active_record_connection_share]
      @connection = args[:connection]
      @mutex = Mutex.new
    end

    def connection
      if @active_record_connection_share && Object.const_defined?('ActiveRecord')
        ActiveRecord::Base.connection.raw_connection
      else
        @connection ||= establish_new
      end
    end

    def execute(stmt, *params)
      @mutex.synchronize do
        QC.log(at: 'exec_sql', sql: stmt.inspect)
        begin
          params = nil if params.empty?
          r = connection.exec(stmt, params)
          result = []
          r.each { |t| result << t }
          result.length > 1 ? result : result.pop
        rescue PG::Error => e
          QC.log(error: e.inspect)
          connection.reset
          raise
        end
      end
    end

    def wait(time, *channels)
      @mutex.synchronize do
        listen_cmds = channels.map { |c| "LISTEN \"#{c}\"" }
        connection.exec(listen_cmds.join(';'))
        wait_for_notify(time)
        unlisten_cmds = channels.map { |c| "UNLISTEN \"#{c}\"" }
        connection.exec(unlisten_cmds.join(';'))
        drain_notify
      end
    end

    def disconnect
      @mutex.synchronize do
        connection.close
      rescue StandardError => e
        QC.log(at: 'disconnect', error: e.message)
      end
    end

    def server_version
      @server_version ||= begin
        version = execute('SHOW server_version_num;')['server_version_num']
        version&.to_i
      end
    end

    private

    def wait_for_notify(t)
      [].tap do |msgs|
        connection.wait_for_notify(t) { |_event, _pid, msg| msgs << msg }
      end
    end

    def drain_notify
      QC.log(at: 'drain_notifications') until connection.notifies.nil?
    end

    def validate!(c)
      return c if c.is_a?(PG::Connection)

      err = "connection must be an instance of PG::Connection, but was #{c.class}"
      raise(ArgumentError, err)
    end

    def establish_new
      QC.log(at: 'establish_conn')
      conn = PG.connect(*normalize_db_url(db_url))
      QC.log(error: conn.error) if conn.status != PG::CONNECTION_OK

      raise "This version of Queue Classic does not support Postgres older than 9.6 (90600). This version is #{conn.server_version}. If you need that support, please use an older version." if conn.server_version < 90_600

      conn.exec("SET application_name = '#{QC.app_name}'")
      conn
    end

    def normalize_db_url(url)
      host = url.host
      host = host.gsub(/%2F/i, '/') if host

      [
        host, # host or percent-encoded socket path
        url.port || 5432,
        nil, nil, # opts, tty
        url.path.gsub('/', ''), # database name
        url.user,
        url.password
      ]
    end

    def db_url
      return @db_url if defined?(@db_url) && @db_url

      url = ENV['QC_DATABASE_URL'] ||
            ENV['DATABASE_URL']    ||
            raise(ArgumentError, 'missing QC_DATABASE_URL or DATABASE_URL')
      @db_url = URI.parse(url)
    end
  end
end
