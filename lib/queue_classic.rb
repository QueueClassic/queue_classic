# frozen_string_literal: true

require_relative "queue_classic/config"

module QC
  extend QC::Config

  # Assign constants for backwards compatibility.
  # They should no longer be used. Prefer the corresponding methods.
  # See +QC::Config+ for more details.
  DEPRECATED_CONSTANTS = {
    :APP_NAME => :app_name,
    :WAIT_TIME => :wait_time,
    :TABLE_NAME => :table_name,
    :QUEUE => :queue,
    :QUEUES => :queues,
    :TOP_BOUND => :top_bound,
    :FORK_WORKER => :fork_worker?,
  }

  def self.const_missing(const_name)
    if DEPRECATED_CONSTANTS.key? const_name
      config_method = DEPRECATED_CONSTANTS[const_name]
      $stderr.puts <<-MSG
The constant QC::#{const_name} is deprecated and will be removed in the future.
Please use the method QC.#{config_method} instead.
      MSG
      QC.public_send config_method
    else
      super
    end
  end

  # Defer method calls on the QC module to the
  # default queue. This facilitates QC.enqueue()
  def self.method_missing(sym, *args, &block)
    if default_queue.respond_to? sym
      default_queue.public_send(sym, *args, &block)
    else
      super
    end
  end

  # Ensure QC.respond_to?(:enqueue) equals true (ruby 1.9 only)
  def self.respond_to_missing?(method_name, include_private = false)
    default_queue.respond_to?(method_name)
  end

  def self.has_connection?
    !default_conn_adapter.nil?
  end

  def self.default_conn_adapter
    Thread.current[:qc_conn_adapter] ||= ConnAdapter.new(active_record_connection_share: rails_connection_sharing_enabled?)
  end

  def self.default_conn_adapter=(conn)
    Thread.current[:qc_conn_adapter] = conn
  end

  def self.log_yield(data)
    t0 = Time.now
    begin
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
    default_conn_adapter.execute("UPDATE #{QC.table_name} SET locked_at = NULL, locked_by = NULL WHERE locked_by NOT IN (SELECT pid FROM pg_stat_activity);")
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
