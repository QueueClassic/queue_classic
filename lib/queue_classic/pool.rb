require 'queue_classic/conn'
require 'thread'

module QC
  # A thread safe container for accessing database connections.
  class Pool

    attr_accessor :conns
    # Creating a new pool will
    # connect all connections in the pool to PostgreSQL.
    def initialize(sz=1)
      @mutex = Mutex.new
      @conns = SizedQueue.new(sz)
      sz.times {@conns.enq(Conn.new)}
    end

    # This method is the primary way to use a connection in
    # the pool. It will take care of checking out the connection
    # and returning the connection to the pool.
    def use(new_on_empty=true)
      raise("Expected a block with Pool#use.") unless block_given?
      c = checkout(new_on_empty)
      result = nil
      begin
        result = yield(c)
      ensure
        checkin(c)
      end
      return result
    end

    # Remove all connections from the pool
    # while disconnecting them from the server.
    def drain!
      until conns.size.zero?
        c = conns.deq
        c.disconnect
      end
    end

    private

    def checkout(new_on_empty=false)
      if new_on_empty
        begin
          conns.deq(true)
        rescue ThreadError
          Conn.new
        end
      else
        conns.deq
      end
    end

    def checkin(c)
      # We synchronize this function
      # because we do a comparison followed by an enqueue.
      @mutex.synchronize do
        if conns.size == conns.max
          c.disconnect
        else
          conns.enq(c)
        end
      end
    end

  end
end
