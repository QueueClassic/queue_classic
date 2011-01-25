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
    end

    def <<(value)
      item = Item.new("value"=>value, "item_id"=>1 )
      @db_conn.exec(
        "INSERT INTO items " +
        "(item_id, value)" +
        "VALUES (#{quote(item.item_id)},#{quote(item.value)})"
      )
    end

    def head
      res = @db_conn.async_exec(
        "SELECT * FROM items ORDER BY items ASC LIMIT 1"
      )
      get_one(res).value
    end

    def tail
      res = @db_conn.async_exec(
        "SELECT * FROM items ORDER BY items DESC LIMIT 1"
      )
      get_one(res).value
    end

    def each
      @db_conn.async_exec(
        "SELECT * FROM items ORDER BY item_id ASC"
      ).each {|r| yield(r["value"]) }
    end

    private

      def get_one(res)
        if res.cmd_tuples > 0
          res.map { |r| Item.new(r) }.pop
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
