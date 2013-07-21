require 'queue_classic'
require 'queue_classic/conn'
require 'json'

module QC
  class Queue

    attr_reader :name, :top_bound
    def initialize(name, top_bound=nil)
      @name = name
      @top_bound = top_bound || QC::TOP_BOUND
    end

    def enqueue(method, *args)
      QC.log_yield(:measure => 'queue.enqueue') do
        s="INSERT INTO #{TABLE_NAME} (q_name, method, args) VALUES ($1, $2, $3)"
        res = Conn.execute(s, name, method, JSON.dump(args))
      end
    end

    def lock(worker_id)
      QC.log_yield(:measure => 'queue.lock') do
        s = "SELECT * FROM lock_head($1, $2, $3, $4)"
        if r = Conn.execute(s, name, top_bound, worker_id, QC::WORKER_UPDATE_TIME * 2)
          locked_by = r['locked_by'].to_i if r['locked_by']
          {:id => r["id"],
            :method => r["method"],
            :args => JSON.parse(r["args"]),
            :locked_by => locked_by }
        end
      end
    end

    def delete(id)
      QC.log_yield(:measure => 'queue.delete') do
        Conn.execute("DELETE FROM #{TABLE_NAME} where id = $1", id)
      end
    end

    def delete_all
      QC.log_yield(:measure => 'queue.delete_all') do
        s = "DELETE FROM #{TABLE_NAME} WHERE q_name = $1"
        Conn.execute(s, name)
      end
    end

    def count
      QC.log_yield(:measure => 'queue.count') do
        s = "SELECT COUNT(*) FROM #{TABLE_NAME} WHERE q_name = $1"
        r = Conn.execute(s, name)
        r["count"].to_i
      end
    end

  end
end
