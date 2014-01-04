require 'queue_classic'
require 'queue_classic/conn_adapter'
require 'json'
require 'time'

module QC
  # The queue class maps a queue abstraction onto a database table.
  class Queue

    def self.heartbeat(wid, jid)
      QC.log_yield(:measure => 'queue.heartbeat') do
        job = Conn.execute(<<-EOS, wid, jid)
          UPDATE #{TABLE_NAME}
          SET updated_at = NOW()
          WHERE locked_by = $1 AND id = $2
          RETURNING *
        EOS
        return job[:locked_by] == wid
      end
    end

    def self.delete(id)
      QC.log_yield(:measure => 'queue.delete') do
        Conn.execute("DELETE FROM #{TABLE_NAME} where id = $1", id)
      end
    end

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

    # enqueue(m,a) inserts a row into the jobs table and trigger a notification.
    # The job's queue is represented by a name column in the row.
    # There is a trigger on the table which will send a NOTIFY event
    # on a channel which corresponds to the name of the queue.
    # The method argument is a string encoded ruby expression. The expression
    # will be separated by a `.` character and then `eval`d.
    # Examples of the method argument include: `puts`, `Kernel.puts`,
    # `MyObject.new.puts`.
    # The args argument will be encoded as JSON and stored as a JSON datatype
    # in the row. (If the version of PG does not support JSON,
    # then the args will be stored as text.
    # The args are stored as a collection and then splatted inside the worker.
    # Examples of args include: `'hello world'`, `['hello world']`,
    # `'hello', 'world'`.
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
          {}.tap do |job|
            job[:id] = r["id"]
            job[:method] = r["method"]
            job[:args] = JSON.parse(r["args"])
            if r["created_at"]
              job[:created_at] = Time.parse(r["created_at"])
              ttl = Integer((Time.now - job[:created_at]) * 1000)
              $stdout.puts("measure#qc.time-to-lock=#{ttl}ms source=#{name}")
            end
          end
        end
      end
    end

    def unlock(id)
      QC.log_yield(:measure => 'queue.unlock') do
        s = "UPDATE #{TABLE_NAME} set locked_at = null where id = $1"
        conn_adapter.execute(s, id)
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
