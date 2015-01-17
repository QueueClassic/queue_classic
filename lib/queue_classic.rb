require_relative "queue_classic/config"

module QC
  extend QC::Config

  # Assign constants for backwards compatibility.
  # They should no longer be used. Prefer the corresponding methods.
  # See +QC::Config+ for more details.
  APP_NAME = self.app_name
  WAIT_TIME = self.wait_time
  TABLE_NAME = self.table_name
  QUEUE = self.queue
  QUEUES = self.queues
  TOP_BOUND = self.top_bound
  FORK_WORKER = self.fork_worker?

  # Defer method calls on the QC module to the
  # default queue. This facilitates QC.enqueue()
  def self.method_missing(sym, *args, &block)
    default_queue.send(sym, *args, &block)
  end

  # Ensure QC.respond_to?(:enqueue) equals true (ruby 1.9 only)
  def self.respond_to_missing?(method_name, include_private = false)
    default_queue.respond_to?(method_name)
  end

  def self.default_queue=(queue)
    @default_queue = queue
  end

  def self.default_queue
    @default_queue ||= begin
      Queue.new(QUEUE)
    end
  end

  def self.has_connection?
    !default_conn_adapter.nil?
  end

  def self.default_conn_adapter
    return @conn_adapter if defined?(@conn_adapter) && @conn_adapter
    if rails_connection_sharing_enabled?
      @conn_adapter = ConnAdapter.new(ActiveRecord::Base.connection.raw_connection)
    else
      @conn_adapter = ConnAdapter.new
    end
    @conn_adapter
  end

  def self.default_conn_adapter=(conn)
    @conn_adapter = conn
  end

  # The worker class instantiated by QC's rake tasks.
  def self.default_worker_class
    @worker_class ||= QC::Worker
  end

  def self.default_worker_class=(worker_class)
    @worker_class = worker_class
  end

  def self.log_yield(data)
    begin
      t0 = Time.now
      yield
    rescue => e
      log({:at => "error", :error => e.inspect}.merge(data))
      raise
    ensure
      t = Integer((Time.now - t0)*1000)
      log(data.merge(:elapsed => t)) unless e
    end
  end

  def self.log(data)
    result = nil
    data = {:lib => "queue-classic"}.merge(data)
    if block_given?
      result = yield
      data.merge(:elapsed => Integer((Time.now - t0)*1000))
    end
    data.reduce(out=String.new) do |s, tup|
      s << [tup.first, tup.last].join("=") << " "
    end
    puts(out) if ENV["DEBUG"]
    return result
  end

  def self.measure(data)
    if ENV['QC_MEASURE']
      $stdout.puts("measure#qc.#{data}")
    end
  end

  # This will unlock all jobs any postgres' PID that is not existing anymore
  # to prevent any infinitely locked jobs
  def self.unlock_jobs_of_dead_workers
    default_conn_adapter.execute("UPDATE #{QC::TABLE_NAME} SET locked_at = NULL, locked_by = NULL WHERE locked_by NOT IN (SELECT pid FROM pg_stat_activity);")
  end

  # private class methods
  class << self
    private

    def rails_connection_sharing_enabled?
      enabled = ENV.fetch('QC_RAILS_DATABASE', 'true') != 'false'
      return false unless enabled
      return Object.const_defined?("ActiveRecord") && ActiveRecord::Base.respond_to?("connection")
    end
  end
end

require_relative "queue_classic/queue"
require_relative "queue_classic/worker"
require_relative "queue_classic/setup"
require_relative "queue_classic/railtie" if defined?(Rails)
