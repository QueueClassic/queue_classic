# frozen_string_literal: true

require_relative 'helper'

class ConfigTest < QCTest
  def setup
    QC.reset_config
  end

  def teardown
    QC.reset_config
  end

  def test_app_name_default
    assert_equal 'queue_classic', QC.app_name
  end

  def test_configure_app_name_with_env_var
    with_env 'QC_APP_NAME' => 'zomg_qc' do
      assert_equal 'zomg_qc', QC.app_name
    end
  end

  def test_wait_time_default
    assert_equal 5, QC.wait_time
  end

  def test_configure_wait_time_with_env_var
    with_env 'QC_LISTEN_TIME' => '7' do
      assert_equal 7, QC.wait_time
    end
  end

  def test_table_name_default
    assert_equal 'queue_classic_jobs', QC.table_name
  end

  def test_queue_default
    assert_equal 'default', QC.queue
    assert_equal 'default', QC.default_queue.name
  end

  def test_configure_queue_with_env_var
    with_env 'QUEUE' => 'priority' do
      assert_equal 'priority', QC.queue
      assert_equal 'priority', QC.default_queue.name
    end
  end

  def test_assign_default_queue
    QC.default_queue = QC::Queue.new 'dispensable'
    assert_equal 'default', QC.queue
    assert_equal 'dispensable', QC.default_queue.name
  end

  def test_queues_default
    assert_equal [], QC.queues
  end

  def test_configure_queues_with_env_var
    with_env 'QUEUES' => 'first,second,third' do
      assert_equal %w[first second third], QC.queues
    end
  end

  def test_configure_queues_with_whitespace
    with_env 'QUEUES' => ' one, two, three ' do
      assert_equal %w[one two three], QC.queues
    end
  end

  def test_top_bound_default
    assert_equal 9, QC.top_bound
  end

  def test_configure_top_bound_with_env_var
    with_env 'QC_TOP_BOUND' => '5' do
      assert_equal 5, QC.top_bound
    end
  end

  def test_fork_worker_default
    refute QC.fork_worker?
  end

  def test_configure_fork_worker_with_env_var
    with_env 'QC_FORK_WORKER' => 'yo' do
      assert QC.fork_worker?
    end
  end

  def test_configuration_constants_are_deprecated
    warning = capture_stderr_output do
      QC::FORK_WORKER
    end
    assert_match 'QC::FORK_WORKER is deprecated', warning
    assert_match 'QC.fork_worker? instead', warning
  end

  class TestWorker < QC::Worker; end

  def test_default_worker_class
    assert_equal QC::Worker, QC.default_worker_class
  end

  def test_configure_default_worker_class_with_env_var
    with_env 'QC_DEFAULT_WORKER_CLASS' => 'ConfigTest::TestWorker' do
      assert_equal TestWorker, QC.default_worker_class
    end
  end

  def test_assign_default_worker_class
    original_worker = QC.default_worker_class
    QC.default_worker_class = TestWorker

    assert_equal TestWorker, QC.default_worker_class
  ensure
    QC.default_worker_class = original_worker
  end
end
