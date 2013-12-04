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


    attr_reader :conn, :name, :top_bound
    def initialize(opts={})
      @conn       =  opts[:conn]       || Conn.new
      @name       =  opts[:name]       || QUEUE_NAME
      @top_bound  =  opts[:top_bound]  || TOP_BOUND
    end

    def names; name.split(',') end
    def names_quoted; names.map { |n| conn.quote(n) }.join(',') end
    def priority_case_statement
      stmt = "CASE"
      names.each_with_index { |n,i| stmt << " WHEN q_name = '#{n}' THEN #{i}" }
      stmt << " END"
      stmt
    end

    def enqueue(method, *args)
      QC.log_yield(:measure => 'queue.enqueue') do
        s = "INSERT INTO #{TABLE_NAME} (q_name, method, args) VALUES ($1, $2, $3)"
        conn.execute(s, names.first, method, JSON.dump(args))
      end
    end

    def lock
      QC.log_yield(:measure => 'queue.lock') do
        s = "SELECT * FROM lock_head($1, $2, $3)"
        if r = conn.execute(s, names_quoted, top_bound, priority_case_statement)
          {:id => r["id"],
            :method => r["method"],
            :args => JSON.parse(r["args"])}
        end
      end
    end

    def wait
      QC.log_yield(:measure => 'queue.wait') do
        conn.wait(names.first)
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
        s = "DELETE FROM #{TABLE_NAME} WHERE q_name IN (#{names_quoted})"
        conn.execute(s)
      end
    end

    def count
      QC.log_yield(:measure => 'queue.count') do
        s = "SELECT COUNT(*) FROM #{TABLE_NAME} WHERE q_name IN (#{names_quoted})"
        r = conn.execute(s)
        r["count"].to_i
      end
    end

  end
end
