module QC
  class Job
    attr_accessor :id, :details, :locked_at

    def initialize(args={})
      @id        = args["id"]
      @details   = JSON.parse(args["details"])
      @locked_at = args["locked_at"]
    end

    def klass
      eval(details["job"].split(".").first)
    end

    def method
      details["job"].split(".").last
    end

    def signature
      details["job"]
    end

    def params
      return [] unless details["params"]
      params = details["params"]
      if params.length == 1
        return params[0]
      else
        params
      end
    end

    def work
      if params.class == Array
        klass.send(method,*params)
      else
        klass.send(method,params)
      end
    end

  end
end
