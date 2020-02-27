# frozen_string_literal: true

require_relative 'conn_adapter'
require 'json'
require 'time'

module QC
  # The queue class maps a queue abstraction onto a database table.
  class Queue
    attr_reader :name, :top_bound

    def initialize(name, top_bound=nil)
      @name = name
      @top_bound = top_bound || QC.top_bound
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
    # This method returns a hash with the id of the enqueued job.
    def enqueue(method, *args)
      QC.log_yield(:measure => 'queue.enqueue') do
        s = "INSERT INTO #{QC.table_name} (q_name, method, args) VALUES ($1, $2, $3) RETURNING id"
        begin
          retries ||= 0
          conn_adapter.execute(s, name, method, JSON.dump(args))
        rescue PG::Error
          if (retries += 1) < 2
            retry
          else
            raise
          end
        end
      end
    end

    # enqueue_at(t,m,a) inserts a row into the jobs table representing a job
    # to be executed not before the specified time.
    # The time argument must be a Time object or a float timestamp. The method
    # and args argument must be in the form described in the documentation for
    # the #enqueue method.
    # This method returns a hash with the id of the enqueued job.
    def enqueue_at(timestamp, method, *args)
      offset = Time.at(timestamp).to_i - Time.now.to_i
      enqueue_in(offset, method, *args)
    end

    # enqueue_in(t,m,a) inserts a row into the jobs table representing a job
    # to be executed not before the specified time offset.
    # The seconds argument must be an integer. The method and args argument
    # must be in the form described in the documentation for the #enqueue
    # method.
    # This method returns a hash with the id of the enqueued job.
    def enqueue_in(seconds, method, *args)
      QC.log_yield(:measure => 'queue.enqueue') do
        s = "INSERT INTO #{QC.table_name} (q_name, method, args, scheduled_at)
             VALUES ($1, $2, $3, now() + interval '#{seconds.to_i} seconds')
             RETURNING id"
        begin
          retries ||= 0
          conn_adapter.execute(s, name, method, JSON.dump(args))
        rescue PG::Error
          if (retries += 1) < 2
            retry
          else
            raise
          end
        end
      end
    end

    def lock
      QC.log_yield(:measure => 'queue.lock') do
        s = <<~SQL
          WITH selected_job AS (
            SELECT id
            FROM queue_classic_jobs
            WHERE
              locked_at IS NULL AND
              q_name = $1 AND
              scheduled_at <= now()
            LIMIT 1
            FOR NO KEY UPDATE SKIP LOCKED
          )
          UPDATE queue_classic_jobs
          SET
            locked_at = now(),
            locked_by = pg_backend_pid()
          FROM selected_job
          WHERE queue_classic_jobs.id = selected_job.id
          RETURNING *
        SQL

        if r = conn_adapter.execute(s, name)
          {}.tap do |job|
            job[:id] = r["id"]
            job[:q_name] = r["q_name"]
            job[:method] = r["method"]
            job[:args] = JSON.parse(r["args"])
            if r["scheduled_at"]
              job[:scheduled_at] = r["scheduled_at"].kind_of?(Time) ? r["scheduled_at"] : Time.parse(r["scheduled_at"])
              ttl = Integer((Time.now - job[:scheduled_at]) * 1000)
              QC.measure("time-to-lock=#{ttl}ms source=#{name}")
            end
          end
        end
      end
    end

    def unlock(id)
      QC.log_yield(:measure => 'queue.unlock') do
        s = "UPDATE #{QC.table_name} SET locked_at = NULL WHERE id = $1"
        conn_adapter.execute(s, id)
      end
    end

    def delete(id)
      QC.log_yield(:measure => 'queue.delete') do
        conn_adapter.execute("DELETE FROM #{QC.table_name} WHERE id = $1", id)
      end
    end

    def delete_all
      QC.log_yield(:measure => 'queue.delete_all') do
        s = "DELETE FROM #{QC.table_name} WHERE q_name = $1"
        conn_adapter.execute(s, name)
      end
    end

    # Count the number of jobs in a specific queue. This returns all
    # jobs, including ones that are scheduled in the future.
    def count
      _count('queue.count', "SELECT COUNT(*) FROM #{QC.table_name} WHERE q_name = $1")
    end

    # Count the number of jobs in a specific queue, except ones scheduled in the future
    def count_ready
      _count('queue.count_scheduled', "SELECT COUNT(*) FROM #{QC.table_name} WHERE q_name = $1 AND scheduled_at <= now()")
    end

    # Count the number of jobs in a specific queue scheduled in the future
    def count_scheduled
      _count('queue.count_scheduled', "SELECT COUNT(*) FROM #{QC.table_name} WHERE q_name = $1 AND scheduled_at > now()")
    end

    private
    def _count(metric_name, sql)
      QC.log_yield(measure: metric_name) do
        r = conn_adapter.execute(sql, name)
        r["count"].to_i
      end
    end
  end
end
