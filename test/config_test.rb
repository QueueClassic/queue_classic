require_relative "helper"

class ConfigTest < QCTest
  def test_app_name_default
    assert_equal "queue_classic", QC.app_name
  end

  def test_configure_app_name_with_env_var
    with_env "QC_APP_NAME" => "zomg_qc" do
      assert_equal "zomg_qc", QC.app_name
    end
  end

  def test_wait_time_default
    assert_equal 5, QC.wait_time
  end

  def test_configure_wait_time_with_env_var
    with_env "QC_LISTEN_TIME" => "7" do
      assert_equal 7, QC.wait_time
    end
  end

  def test_table_name_default
    assert_equal "queue_classic_jobs", QC.table_name
  end

  def test_queue_default
    assert_equal "default", QC.queue
  end

  def test_configure_queue_with_env_var
    with_env "QUEUE" => "priority" do
      assert_equal "priority", QC.queue
    end
  end

  def test_queues_default
    assert_equal [], QC.queues
  end

  def test_configure_queues_with_env_var
    with_env "QUEUES" => "first,second,third" do
      assert_equal %w(first second third), QC.queues
    end
  end

  def test_configure_queues_with_whitespace
    with_env "QUEUES" => " one, two, three " do
      assert_equal %w(one two three), QC.queues
    end
  end

  def test_top_bound_default
    assert_equal 9, QC.top_bound
  end

  def test_configure_top_bound_with_env_var
    with_env "QC_TOP_BOUND" => "5" do
      assert_equal 5, QC.top_bound
    end
  end

  def test_fork_worker_default
    refute QC.fork_worker?
  end

  def test_configure_fork_worker_with_env_var
    with_env "QC_FORK_WORKER" => "yo" do
      assert QC.fork_worker?
    end
  end

  private
  def with_env(temporary_environment)
    original_environment = {}
    temporary_environment.each do |name, value|
      original_environment[name] = ENV[name]
      ENV[name] = value
    end
    yield
  ensure
    original_environment.each { |name, value| ENV[name] = value }
  end
end
