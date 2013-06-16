module QC
  class WorkerManager

    def initialize(name=nil)
      @queue = Queue.new(name)
    end

    def start(num_threads)
      num_threads.map do
        Thread.new do
          @workers << Worker.new(@queue).tap {|w| w.start}
        end
      end
    end

    def stop
      @workers.each {|w| w.stop}
    end

  end
end
