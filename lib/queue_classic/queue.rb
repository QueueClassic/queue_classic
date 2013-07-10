require 'queue_classic'
require 'queue_classic/pool'
require 'json'

module QC
  class Queue

    attr_reader :pool, :name, :top_bound
    def initialize(opts={})
      @pool       = opts[:pool]       || Pool.new
      @name       = opts[:name]       || QC::QUEUE
      @top_bound  = opts[:top_bound]  || QC::TOP_BOUND
    end

    def enqueue(method, *args)
      QC.log_yield(:measure => 'queue.enqueue') do
        s="INSERT INTO #{TABLE_NAME} (q_name, method, args) VALUES ($1, $2, $3)"
        res = @pool.use {|c| c.execute(s, name, method, JSON.dump(args))}
      end
    end

    def lock
      QC.log_yield(:measure => 'queue.lock') do
        s = "SELECT * FROM lock_head($1, $2)"
        if r = @pool.use {|c| c.execute(s, name, top_bound)}
          {:id => r["id"],
            :method => r["method"],
            :args => JSON.parse(r["args"])}
        end
      end
    end

    def wait
      QC.log_yield(:measure => 'queue.wait') do
        @pool.use {|c| c.wait(name)}
      end
    end

    def delete(id)
      QC.log_yield(:measure => 'queue.delete') do
        s = "DELETE FROM #{TABLE_NAME} where id = $1"
        @pool.use {|c| c.execute(s, id)}
      end
    end

    def delete_all
      QC.log_yield(:measure => 'queue.delete_all') do
        s = "DELETE FROM #{TABLE_NAME} WHERE q_name = $1"
        @pool.use {|c| c.execute(s, name)}
      end
    end

    def count
      QC.log_yield(:measure => 'queue.count') do
        s = "SELECT COUNT(*) FROM #{TABLE_NAME} WHERE q_name = $1"
        r = @pool.use {|c| c.execute(s, name)}
        r["count"].to_i
      end
    end

  end
end
