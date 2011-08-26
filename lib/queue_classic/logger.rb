module QC
  module Logger

    extend self

    def ruby_logger
      @@logger ||= ::Logger.new(STDOUT)
    end

    def puts(msg)
      if VERBOSE
        ruby_logger.debug(msg)
      end
    end

  end
end
