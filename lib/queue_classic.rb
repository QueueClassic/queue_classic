module QC
  # You can use the APP_NAME to query for
  # postgres related process information in the
  # pg_stat_activity table.
  APP_NAME = ENV["QC_APP_NAME"] || "queue_classic"

  # Number of seconds to block on the listen chanel for new jobs.
  WAIT_TIME = (ENV["QC_LISTEN_TIME"] || 5).to_i

  # Why do you want to change the table name?
  # Just deal with the default OK?
  # If you do want to change this, you will
  # need to update the PL/pgSQL lock_head() function.
  # Come on. Don't do it.... Just stick with the default.
  TABLE_NAME = "queue_classic_jobs"

  # Each row in the table will have a column that
  # notes the queue. You can point your workers
  # at different queues but only one at a time.
  QUEUE = ENV["QUEUE"] || "default"
  QUEUES = (ENV["QUEUES"] && ENV["QUEUES"].split(",")) || []

  # Set this to 1 for strict FIFO.
  # There is nothing special about 9....
  TOP_BOUND = (ENV["QC_TOP_BOUND"] || 9).to_i

  # Set this variable if you wish for
  # the worker to fork a UNIX process for
  # each locked job. Remember to re-establish
  # any database connections. See the worker
  # for more details.
  FORK_WORKER = !ENV["QC_FORK_WORKER"].nil?

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
    !@conn_adapter.nil?
  end

  def self.default_conn_adapter
    return @conn_adapter if @conn_adapter
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
    @conn_adapter.execute("UPDATE #{QC::TABLE_NAME} SET locked_at = NULL, locked_by = NULL WHERE locked_by NOT IN (SELECT pid FROM pg_stat_activity);")
  end

  private
  def self.rails_connection_sharing_enabled?
    enabled = ENV.fetch('QC_RAILS_DATABASE', 'true') != 'false'
    return false unless enabled
    return Object.const_defined?("ActiveRecord") && ActiveRecord::Base.respond_to?("connection")
  end
end

require_relative "queue_classic/queue"
require_relative "queue_classic/worker"
require_relative "queue_classic/setup"
require_relative "queue_classic/railtie" if defined?(Rails)
