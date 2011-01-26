require 'pg'

module QC
  class Item
    attr_accessor :item_id, :value
    def initialize(args={})
      @item_id  = args["item_id"]
      @value    = args["value"]
    end
  end

  class DurableArray
    include Enumerable

    def initialize(args={})
      @db_conn  = PGconn.open(:dbname => args[:dbname])
      execute("SET client_min_messages TO 'warning'")
    end

    def <<(value)
      item = Item.new("value"=>value)
      execute(
        "INSERT INTO items " +
        "(value)" +
        "VALUES (#{quote(item.value)})"
      )
    end

    def first
      head
    end

    def last
      tail
    end

    def delete(item)
      res = execute(
        "DELETE FROM items WHERE item_id = #{item.item_id}"
      )
    end

    def find(item)
      res = execute(
        "SELECT * FROM items WHERE item_id = #{item.item_id}"
      )
      get_one(res)
    end

    def [](index)
      res = execute(
        "SELECT * FROM items ORDER BY item_id ASC LIMIT 1 OFFSET #{index}"
      )
      get_one(res)
    end

    def head
      res = execute(
        "SELECT * FROM items ORDER BY items ASC LIMIT 1"
      )
      get_one(res)
    end

    def tail
      res = execute(
        "SELECT * FROM items ORDER BY items DESC LIMIT 1"
      )
      get_one(res)
    end

    def each
      execute(
        "SELECT * FROM items ORDER BY item_id ASC"
      ).each {|r| yield(r["value"]) }
    end

    private

      def execute(sql)
        @db_conn.async_exec(sql)
      end

      def get_one(res)
        if res.cmd_tuples > 0
          res.map {|r| Item.new(r)}.pop
        end
      end

      def quote(value)
        if value.kind_of?(String)
          "'#{value}'"
        elsif value.kind_of?(Numeric)
          value
        end
      end

  end
end
