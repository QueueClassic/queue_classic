require "pg"

require "logger"
require "uri"

$: << File.expand_path(__FILE__, "lib")

require "queue_classic/okjson"
require "queue_classic/worker"
require "queue_classic/conn"
require "queue_classic/queries"
require "queue_classic/queue"
require "queue_classic/job"

module QC
  Root = File.expand_path(File.dirname(__FILE__))
  SqlFunctions = File.join(QC::Root, "/sql/ddl.sql")
  DropSqlFunctions = File.join(QC::Root, "/sql/drop_ddl.sql")

  Log = Logger.new($stdout)
  Log.level = (ENV["QC_LOG_LEVEL"] || Logger::DEBUG).to_i
  Log.info("program=queue_classic log=true")

  TABLE_NAME = ENV["QUEUE"] || "queue_classic_jobs"
  TOP_BOUND = (ENV["QC_TOP_BOUND"] || 9).to_i
  LISTENING_WORKER = !ENV["QC_LISTENING_WORKER"].nil?
  MAX_LOCK_ATTEMPTS = (ENV["QC_MAX_LOCK_ATTEMPTS"] || 5).to_i

  Conn.execute("SET application_name = 'queue_classic'")

  def self.method_missing(sym, *args, &block)
    default_queue.send(sym, *args, &block)
  end

  def self.default_queue
    @default_queue ||= begin
      Queue.new(TABLE_NAME, TOP_BOUND, LISTENING_WORKER)
    end
  end

end
