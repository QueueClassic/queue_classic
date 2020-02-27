# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'queue_classic/version'

Gem::Specification.new do |spec|
  spec.name          = "queue_classic"
  spec.email         = "r@32k.io"
  spec.version       = QC::VERSION
  spec.description   = "queue_classic is a queueing library for Ruby apps. (Rails, Sinatra, Etc...) queue_classic features asynchronous job polling, database maintained locks and no ridiculous dependencies. As a matter of fact, queue_classic only requires pg."
  spec.summary       = "Simple, efficient worker queue for Ruby & PostgreSQL."
  spec.authors       = ["Ryan Smith (♠ ace hacker)"]
  spec.homepage      = "http://github.com/QueueClassic/queue_classic"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.require_paths = %w[lib]

  spec.add_dependency "pg", ">= 0.17", "< 2.0"
  spec.add_development_dependency "activerecord", ">= 5.0.0", "< 6.1"
end
