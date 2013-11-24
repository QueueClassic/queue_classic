require 'queue_classic'
require 'queue_classic/conn'
require 'json'

module QC
  class Queue
    TABLE_NAME = "queue_classic_jobs"
    # Each row in the table will have a column that
    # notes the queue.
    QUEUE_NAME = ENV["QUEUE"] || "default"
    # Set this to 1 for strict FIFO.
    TOP_BOUND = (ENV["QC_TOP_BOUND"] || 9).to_i


    attr_reader :conn, :names, :top_bound
    def initialize(opts={})
      @conn       = opts[:conn]       || Conn.new
      @names      = opts[:name]       || opts[:names] || QUEUE_NAME
      @top_bound  = opts[:top_bound]  || TOP_BOUND
    end

    def enqueue(method, *args)
      QC.log_yield(:measure => 'queue.enqueue') do
        s = "INSERT INTO #{TABLE_NAME} (q_name, method, args) VALUES ($1, $2, $3)"
        conn.execute(s, first_name, method, JSON.dump(args))
      end
    end

    def lock
      QC.log_yield(:measure => 'queue.lock') do
        s = "SELECT * FROM lock_head($1, $2)"
        if r = conn.execute(s, names, top_bound)
          {:id => r["id"],
            :method => r["method"],
            :args => JSON.parse(r["args"])}
        end
      end
    end

    def wait
      QC.log_yield(:measure => 'queue.wait') do
        conn.wait(first_name)
      end
    end

    def delete(id)
      QC.log_yield(:measure => 'queue.delete') do
        s = "DELETE FROM #{TABLE_NAME} where id = $1"
        conn.execute(s, id)
      end
    end

    def delete_all
      QC.log_yield(:measure => 'queue.delete_all') do
        s = "DELETE FROM #{TABLE_NAME} WHERE strpos($1, q_name) > 0"
        conn.execute(s, names)
      end
    end

    def count
      QC.log_yield(:measure => 'queue.count') do
        s = "SELECT COUNT(*) FROM #{TABLE_NAME} WHERE strpos($1, q_name) > 0"
        r = conn.execute(s, names)
        r["count"].to_i
      end
    end

    def first_name
      names.split(',').first
    end

  end
end
