require "pg"

require "logger"
require "uri"

$: << File.expand_path(__FILE__, "lib")

require "queue_classic/okjson"
require "queue_classic/conn"
require "queue_classic/queries"
require "queue_classic/queue"
require "queue_classic/worker"

module QC

  Root = File.expand_path(File.dirname(__FILE__))
  SqlFunctions = File.join(QC::Root, "/sql/ddl.sql")
  DropSqlFunctions = File.join(QC::Root, "/sql/drop_ddl.sql")

  Log = Logger.new($stdout)
  Log.level = (ENV["QC_LOG_LEVEL"] || Logger::DEBUG).to_i
  Log.info("program=queue_classic log=true")

  DB_URL =
    ENV["QC_DATABASE_URL"] ||
    ENV["DATABASE_URL"]    ||
    raise(ArgumentError, "missing QC_DATABASE_URL or DATABASE_URL")

  # You can use the APP_NAME to query for
  # postgres related process information in the
  # pg_stat_activity table. Don't set this unless
  # you are using PostgreSQL > 9.0
  APP_NAME = ENV["QC_APP_NAME"]

  TABLE_NAME = ENV["QC_TABLE_NAME"] || "queue_classic_jobs"

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
  # each locked job. Remember to restablish
  # any database connectoins. See the worker
  # for more details.
  FORK_WORKER = !ENV["QC_FORK_WORKER"].nil?

  # The worker uses an exponential backoff
  # algorithm to lock a job. This value will be used
  # as the max exponent.
  MAX_LOCK_ATTEMPTS = (ENV["QC_MAX_LOCK_ATTEMPTS"] || 5).to_i

  if APP_NAME
    Conn.execute("SET application_name = '#{APP_NAME}'")
  end

  def self.method_missing(sym, *args, &block)
    default_queue.send(sym, *args, &block)
  end

  def self.default_queue
    @default_queue ||= begin
      Queue.new(QUEUE, LISTENING_WORKER)
    end
  end

end
