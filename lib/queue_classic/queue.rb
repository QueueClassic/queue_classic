require 'queue_classic'
require 'queue_classic/conn_adapter'
require 'json'

module QC
  class Queue

    attr_reader :name, :top_bound
    def initialize(name, top_bound=nil)
      @name = name
      @top_bound = top_bound || QC::TOP_BOUND
    end

    def conn_adapter=(a)
      @adapter = a
    end

    def conn_adapter
      @adapter ||= QC.default_conn_adapter
    end

    def enqueue(method, *args)
      QC.log_yield(:measure => 'queue.enqueue') do
        s="INSERT INTO #{TABLE_NAME} (q_name, method, args) VALUES ($1, $2, $3)"
        res = conn_adapter.execute(s, name, method, JSON.dump(args))
      end
    end

    def lock
      QC.log_yield(:measure => 'queue.lock') do
        s = "SELECT * FROM lock_head($1, $2)"
        if r = conn_adapter.execute(s, name, top_bound)
          {:id => r["id"],
            :method => r["method"],
            :args => JSON.parse(r["args"])}
        end
      end
    end

    def delete(id)
      QC.log_yield(:measure => 'queue.delete') do
        conn_adapter.execute("DELETE FROM #{TABLE_NAME} where id = $1", id)
      end
    end

    def delete_all
      QC.log_yield(:measure => 'queue.delete_all') do
        s = "DELETE FROM #{TABLE_NAME} WHERE q_name = $1"
        conn_adapter.execute(s, name)
      end
    end

    def count
      QC.log_yield(:measure => 'queue.count') do
        s = "SELECT COUNT(*) FROM #{TABLE_NAME} WHERE q_name = $1"
        r = conn_adapter.execute(s, name)
        r["count"].to_i
      end
    end

  end
end
