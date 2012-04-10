module QC
  module Queries
    extend self

    def insert(q_name, method, args, chan=nil)
      QC.log_yield(:action => "insert_job") do
        s = "INSERT INTO #{TABLE_NAME} (q_name, method, args) VALUES ($1, $2, $3)"
        res = Conn.execute(s, q_name, method, OkJson.encode(args))
        Conn.notify(chan) if chan
      end
    end
    def install_plpgsql
      Conn.execute(%{
        DROP LANGUAGE IF EXISTS plpgsql CASCADE;
        CREATE OR REPLACE FUNCTION plpgsql_call_handler() 
                           RETURNS language_handler AS '$libdir/plpgsql' LANGUAGE C;
        CREATE TRUSTED LANGUAGE plpgsql HANDLER "plpgsql_call_handler"; 
      })
    end

    def lock_head(q_name, top_bound)
      s = "SELECT * FROM lock_head($1, $2)"
      if r = Conn.execute(s, q_name, top_bound)
        {
          :id     => r["id"],
          :method => r["method"],
          :args   => OkJson.decode(r["args"])
        }
      end
    end

    def count(q_name=nil)
      s = "SELECT COUNT(*) FROM #{TABLE_NAME}"
      s << " WHERE q_name = $1" if q_name
      r = Conn.execute(*[s, q_name].compact)
      r["count"].to_i
    end

    def delete(id)
      Conn.execute("DELETE FROM #{TABLE_NAME} where id = $1", id)
    end

    def delete_all(q_name=nil)
      s = "DELETE FROM #{TABLE_NAME}"
      s << "WHERE q_name = $1" if q_name
      Conn.execute(*[s, q_name].compact)
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
