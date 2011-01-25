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

      def client_min_messages=(level)
      end


  end
end
