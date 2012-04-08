require "thread"

module Scrolls
  extend self

  def log(data, &blk)
    Log.log(data, &blk)
  end

  def log_exception(data, e)
    Log.log_exception(data, e)
  end

  module Log
    extend self

    LOG_LEVEL = (ENV["QC_LOG_LEVEL"] || 3).to_i
    LOG_LEVEL_MAP = {
      "fatal" => 0,
      "error" => 1,
      "warn"  => 2,
      "info"  => 3,
      "debug" => 4
    }

    attr_accessor :stream

    def start(out = nil)
      # This allows log_exceptions below to pick up the defined output,
      # otherwise stream out to STDERR
      @defined = out.nil? ? false : true
      sync_stream(out)
    end

    def sync_stream(out = nil)
      out = STDOUT if out.nil?
      @stream = out
      @stream.sync = true
    end

    def mtx
      @mtx ||= Mutex.new
    end

    def write(data)
      if log_level_ok?(data[:level])
        msg = unparse(data)
        mtx.synchronize do
          @stream.puts(msg)
        end
      end
    end

    def unparse(data)
      data.map do |(k, v)|
        if (v == true)
          k.to_s
        elsif v.is_a?(Float)
          "#{k}=#{format("%.3f", v)}"
        elsif v.nil?
          nil
        else
          v_str = v.to_s
          if (v_str =~ /^[a-zA-z0-9\-\_\.]+$/)
            "#{k}=#{v_str}"
          else
            "#{k}=\"#{v_str.sub(/".*/, "...")}\""
          end
        end
      end.compact.join(" ")
    end

    def log(data, &blk)
      unless blk
        write(data)
      else
        start = Time.now
        res = nil
        log(data.merge(:at => :start))
        begin
          res = yield
        rescue StandardError, Timeout::Error => e
          log(data.merge(
            :at           => :exception,
            :reraise      => true,
            :class        => e.class,
            :message      => e.message,
            :exception_id => e.object_id.abs,
            :elapsed      => Time.now - start
          ))
          raise(e)
        end
        log(data.merge(:at => :finish, :elapsed => Time.now - start))
        res
      end
    end

    def log_exception(data, e)
      sync_stream(STDERR) unless @defined
      log(data.merge(
        :exception    => true,
        :class        => e.class,
        :message      => e.message,
        :exception_id => e.object_id.abs
      ))
      if e.backtrace
        bt = e.backtrace.reverse
        bt[0, bt.size-6].each do |line|
          log(data.merge(
            :exception    => true,
            :exception_id => e.object_id.abs,
            :site         => line.gsub(/[`'"]/, "")
          ))
        end
      end
    end

    def log_level_ok?(level)
      if level
        LOG_LEVEL_MAP[level.to_s] <= LOG_LEVEL
      else
        true
      end
    end

  end
end
