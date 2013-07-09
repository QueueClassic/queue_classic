module QC
  class Queue

    attr_reader :name, :top_bound
    def initialize(name, top_bound=nil)
      @name = name
      @top_bound = top_bound || QC::TOP_BOUND
    end

    def enqueue(method, *args)
      QC.log_yield(:action => "insert_job") do
        s="INSERT INTO #{TABLE_NAME} (q_name, method, args) VALUES ($1, $2, $3)"
        res = Conn.execute(s, name, method, JSON.dump(args))
      end
    end

    def lock
      s = "SELECT * FROM lock_head($1, $2)"
      if r = Conn.execute(s, name, top_bound)
        {
          :id     => r["id"],
          :method => r["method"],
          :args   => JSON.parse(r["args"])
        }
      end

    end

    def delete(id)
      Conn.execute("DELETE FROM #{TABLE_NAME} where id = $1", id)
    end

    def delete_all
      s = "DELETE FROM #{TABLE_NAME} WHERE q_name = $1"
      Conn.execute(s, name)
    end

    def count
      s = "SELECT COUNT(*) FROM #{TABLE_NAME} WHERE q_name = $1"
      r = Conn.execute(s, name)
      r["count"].to_i
    end

  end
end
