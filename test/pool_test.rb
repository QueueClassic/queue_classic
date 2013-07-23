require File.expand_path("../helper.rb", __FILE__)

class PoolTest < QCTest

  def setup
    init_db
  end

  def test_pool_size
    n = 2
    p = QC::Pool.new(n)
    s = 'SELECT count(*) from pg_stat_activity where datname=current_database()'
    num_conns = p.use {|c| c.execute(s)['count'].to_i}
    assert_equal(n, num_conns)
    p.drain!
  end

end
