module QueueClassic
  #
  # A runable payload is a way of decoding the payload of a Message into a
  # Class#method(args) format so that you can then just invoke #call on it 
  # so it does its thing.
  #
  # A RunablePlayload is created with a JSON string. The fields in the String
  # define different methodologies for encoding a Class#method#args invocation.
  #
  # There is the QueueClassic style, which is of the form:
  #
  #   { "job" => "Module::Class.method", "params" => [ 'foo', 42 ] }
  #
  # And there is the Resque style
  #
  #   { "class" => "Module::Class", "args" => [ 'foo', 42 ] }
  #
  # In the resque style, it is assumed the method to call is 'perform'
  #
  # RunablePayload can work with both styles. Runable works by passing in that
  # initial JSON string, and then just calling 'run'.
  #
  class RunablePayload
    class Error < ::QueueClassic::Error ; end

    # The Class of the Payload
    attr_reader :klass

    # The method on Class to invoke
    attr_reader :method

    # The arguments to pass to method
    attr_reader :args

    # Create a new RunablePayload
    #
    # json_string - the argument name should be self explanatory.
    #
    # Returns a new RunablePayload.
    def initialize( json_string )
      raise Error, "really? nil/false as the payload?" unless json_string
      @opts = ::JSON.parse( json_string )
      @klass, @method, @args = build_qc_style(@opts) || build_resque_style(@opts)
      raise Error, "I don't know how to build a runable payload from #{@opts.inspect}" unless @klass
      raise Error, "#{@klass}.#{method} is not implemented" unless @klass.respond_to?( @method )
    end

    def to_s
      "#{@klass}.#{@method}( #{@args.map { |a| a.inspect }.join(", ")} )"
    end

    # Run the Class#method(args)
    #
    def run
      @klass.send( @method, *@args )
    end

    private

    def build_qc_style( opts )
      return false unless @opts.has_key?("job") and @opts.has_key?("params")

      class_name, method = opts['job'].split(".")
      klass = constantize( class_name )
      args = opts['params']

      return [ klass, method, args ]
    end

    def build_resque_style( opts )
      return false unless @opts.has_key?("class") and @opts.has_key?("args")

      klass  = constantize( opts['class'] )
      method = 'perform'
      args   = opts['args']

      return [ klass, method, args ]
    end


    # Pulled from Resque:
    # https://github.com/defunkt/resque/blob/master/lib/resque/helpers.rb#L36
    #
    # Given a word with dashes, returns a camel cased version of it.
    #
    # classify('job-name') # => 'JobName'
    def classify(dashed_word)
      dashed_word.split('-').each { |part| part[0] = part[0].chr.upcase }.join
    end

    # Pulled from Resque, which looks to be a better version of what is in
    # ActiveSupport.
    # https://github.com/defunkt/resque/blob/master/lib/resque/helpers.rb#L43
    #
    # Tries to find a constant with the name specified in the argument string:
    #
    # constantize("Module") # => Module
    # constantize("Test::Unit") # => Test::Unit
    #
    # The name is assumed to be the one of a top-level constant, no matter
    # whether it starts with "::" or not. No lexical context is taken into
    # account:
    #
    # C = 'outside'
    # module M
    #   C = 'inside'
    #   C # => 'inside'
    #   constantize("C") # => 'outside', same as ::C
    # end
    #
    # NameError is raised when the constant is unknown.
    def constantize(camel_cased_word)
      camel_cased_word = camel_cased_word.to_s

      if camel_cased_word.include?('-')
        camel_cased_word = classify(camel_cased_word)
      end

      names = camel_cased_word.split('::')
      names.shift if names.empty? || names.first.empty?

      constant = Object
      names.each do |name|
        args = Module.method(:const_get).arity != 1 ? [false] : []

        if constant.const_defined?(name, *args)
          constant = constant.const_get(name)
        else
          constant = constant.const_missing(name)
        end
      end
      constant
    end
  end
end
