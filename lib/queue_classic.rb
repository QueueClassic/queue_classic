module QC
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
    @default_queue ||= Queue.new
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
      start = Time.now
      result = yield
      data.merge(:elapsed => Integer((Time.now - start)*1000))
    end
    data.reduce(out=String.new) do |s, tup|
      s << [tup.first, tup.last].join("=") << " "
    end
    puts(out) if ENV["DEBUG"]
    return result
  end
end

require "queue_classic/queue"
require "queue_classic/worker"
require "queue_classic/setup"
require "queue_classic/railtie" if defined?(Rails)
