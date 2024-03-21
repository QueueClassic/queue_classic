# frozen_string_literal: true

require "bundler"
require "minitest/reporters"

Bundler.setup :default, :test

if ENV['CIRCLECI'] == "true"
  Minitest::Reporters.use! Minitest::Reporters::JUnitReporter.new
else
  Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
end

ENV["DATABASE_URL"] ||= "postgres:///queue_classic_test"

require_relative '../lib/queue_classic'
require "stringio"
require 'timeout'
require "minitest/autorun"

class QCTest < Minitest::Test

  def setup
    init_db
  end

  def teardown
    QC.delete_all
  end

  def init_db
    c = QC::ConnAdapter.new
    c.execute("SET client_min_messages TO 'warning'")
    QC::Setup.drop(c.connection)
    QC::Setup.create(c.connection)
    c.execute(File.read('./test/helper.sql'))
    c.disconnect
  end

  def capture_stderr_output
    original_stderr = $stderr
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = original_stderr
  end

  def capture_debug_output
    original_debug = ENV['DEBUG']
    original_stdout = $stdout

    ENV['DEBUG'] = "true"
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    ENV['DEBUG'] = original_debug
    $stdout = original_stdout
  end

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

  def stub_any_instance(class_name, method_name, definition)
    new_method_name = "new_#{method_name}"
    original_method_name = "original_#{method_name}"

    method_present = class_name.instance_methods(false).include? method_name

    if method_present
      class_name.send(:alias_method, original_method_name, method_name)
      class_name.send(:define_method, new_method_name, definition)
      class_name.send(:alias_method, method_name, new_method_name)

      yield
    else
      message = "#{class_name} does not have method #{method_name}."
      message << "\nAvailable methods: #{class_name.instance_methods(false)}"
      raise ArgumentError.new message
    end
  ensure
    if method_present
      class_name.send(:alias_method, method_name, original_method_name)
      class_name.send(:undef_method, new_method_name)
    end
  end
end
