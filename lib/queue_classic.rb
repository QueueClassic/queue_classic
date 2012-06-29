require "scrolls"
require "pg"
require "uri"

$: << File.expand_path(__FILE__, "lib")

require "queue_classic/okjson"
require "queue_classic/conn"
require "queue_classic/queries"
require "queue_classic/queue"
require "queue_classic/worker"
require "queue_classic/setup"

module QC
  # ENV["LOG_LEVEL"] is used in Scrolls
  Scrolls::Log.start

  Root = File.expand_path("..", File.dirname(__FILE__))
  SqlFunctions = File.join(QC::Root, "/sql/ddl.sql")
  DropSqlFunctions = File.join(QC::Root, "/sql/drop_ddl.sql")
  CreateTable = File.join(QC::Root, "/sql/create_table.sql")

  # You can use the APP_NAME to query for
  # postgres related process information in the
  # pg_stat_activity table. Don't set this unless
  # you are using PostgreSQL > 9.0
  if APP_NAME = ENV["QC_APP_NAME"]
    Conn.execute("SET application_name = '#{APP_NAME}'")
  end

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

  # Set this to 1 for strict FIFO.
  # There is nothing special about 9....
  TOP_BOUND = (ENV["QC_TOP_BOUND"] || 9).to_i

  # If you are using PostgreSQL > 9
  # then you will have access to listen/notify with payload.
  # Set this value if you wish to make your worker more efficient.
  LISTENING_WORKER = !ENV["QC_LISTENING_WORKER"].nil?

  # Set this variable if you wish for
  # the worker to fork a UNIX process for
  # each locked job. Remember to re-establish
  # any database connections. See the worker
  # for more details.
  FORK_WORKER = !ENV["QC_FORK_WORKER"].nil?

  # The worker uses an exponential back-off
  # algorithm to lock a job. This value will be used
  # as the max exponent.
  MAX_LOCK_ATTEMPTS = (ENV["QC_MAX_LOCK_ATTEMPTS"] || 5).to_i

  # If you want the PID of the current process 
  # written to an external file, set this
  # variable to the desired location.
  if PIDFILE=ENV["QC_PIDFILE"]
    File.open(PIDFILE, 'w') { |f| f << Process.pid }
  end

  # Defer method calls on the QC module to the
  # default queue. This facilitates QC.enqueue()
  def self.method_missing(sym, *args, &block)
    default_queue.send(sym, *args, &block)
  end

  def self.default_queue
    @default_queue ||= begin
      Queue.new(QUEUE, LISTENING_WORKER)
    end
  end

  def self.log_yield(data)
    begin
      t0 = Time.now
      yield
    rescue => e
      log({:level => :error, :error => e.class, :message => e.message.strip}.merge(data))
      raise
    ensure
      t = Integer((Time.now - t0)*1000)
      log(data.merge(:elapsed => t)) unless e
    end
  end

  def self.log(data)
    Scrolls.log({:lib => :queue_classic}.merge(data))
  end

end
