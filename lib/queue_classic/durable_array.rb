module QC
  class DurableArray

    def initialize(args={})
      get_handler(args)
    end

    def <<(details)
      raise "Should be implemented by a handler"
    end

    def count
      raise "Should be implemented by a handler"
    end

    def delete(job)
      raise "Should be implemented by a handler"
    end

    def find(job)
      raise "Should be implemented by a handler"
    end

    def first
      raise "Should be implemented by a handler"
    end

    def each
      raise "Should be implemented by a handler"
    end

    def find_one
      raise "Should be implemented by a handler"
    end

    def with_log(msg)
      raise "Should be implemented by a handler"
    end

    def log(msg)
      puts "| \t" + msg
    end

    def get_handler(args)
      if args.key?(:adapter)
        begin
          require "queue_classic/handlers/#{args[:adapter]}_handler"
        rescue
          "Please install the #{args[:adapter]} adapter gem"
        end

        adapter_method = "#{args[:adapter]}_initialize"
        unless respond_to?(adapter_method) then raise AdapterInitializeMethodNotFound end
        send adapter_method.to_s, args

      elsif
        db_params = URI.parse(args[:database])
        unless !db_params.scheme.nil? then raise AdapterHandlerNotSpecified, "database configuration does not specify adapter" end
        get_handler(args.merge(:adapter => db_params.scheme))

      else
        raise AdapterHandlerNotSpecified, "database configuration does not specify adapter"

      end

    end

  end
end

