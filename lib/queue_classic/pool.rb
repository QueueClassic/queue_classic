require 'queue_classic/conn'
require 'thread'

module QC
  class Pool

    attr_accessor :conns
    def initialize(sz=1)
      @mutex = Mutex.new
      @conns = SizedQueue.new(sz)
      sz.times {@conns.enq(Conn.new)}
    end

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
