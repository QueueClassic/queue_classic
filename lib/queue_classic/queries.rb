module QC
  module Queries
    extend self

    def insert(table, method, args, chan=nil)
      s = "INSERT INTO #{table} (method, args) VALUES ($1, $2)"
      res = Conn.execute(s, method, OkJson.encode(args))
      Conn.notify(chan) if chan
    end

    def lock_head(table, top_bound)
      q = "SELECT * FROM lock_head($1, $2)"
      if r = Conn.execute(q, table, top_bound)
        {
          :id     => r["id"],
          :method => r["method"],
          :args   => OkJson.decode(r["args"])
        }
      end
    end

    def count(table)
      r = Conn.execute("SELECT COUNT(*) FROM #{table}")
      r["count"].to_i
    end

    def delete(table, id)
      Conn.execute("DELETE FROM #{table} where id = $1", id)
    end

    def delete_all(table)
      Conn.execute("DELETE FROM #{table}")
    end

    def load_functions
      file = File.open(SqlFunctions)
      Conn.transaction do
        Conn.execute(file.read)
      end
      file.close
    end

    def drop_functions
      file = File.open(DropSqlFunctions)
      Conn.transaction do
        Conn.execute(file.read)
      end
      file.close
    end

  end
end
