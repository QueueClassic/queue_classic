module QC
  class Job
    attr_accessor :id, :details, :locked_at

    def initialize(args={})
      @id        = args["id"]
      @details   = args["details"]
      @locked_at = args["locked_at"]
    end

    def klass
      Kernel.const_get(details["job"].split(".").first)
    end

    def method
      details["job"].split(".").last
    end

    def params
      params = details["params"]
      if params.length == 1
        return params[0]
      else
        params
      end
    end

  end
end
