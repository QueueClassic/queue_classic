module QC
  module Api

    def enqueue(*args)
      queue.enqueue(args)
    end

    def dequeue(*args)
      queue.dequeue(args)
    end

    def queue
      @queue ||= Queue.setup
    end

  end
end
