#encoding: UTF-8
Gem::Specification.new do |s|
  s.name          = "queue_classic"
  s.email         = "ryan@heroku.com"
  s.version       = "2.0.1"
  s.date          = "2012-07-23"
  s.description   = "queue_classic is a queueing library for Ruby apps. (Rails, Sinatra, Etc...) queue_classic features asynchronous job polling, database maintained locks and no ridiculous dependencies. As a matter of fact, queue_classic only requires pg."
  s.summary       = "postgres backed queue"
  s.authors       = ["Ryan Smith (♠ ace hacker)"]
  s.homepage      = "http://github.com/ryandotsmith/queue_classic"
  s.license       = "MIT"

  files = []
  files << "readme.md"
  files << Dir["sql/**/*.sql"]
  files << Dir["{lib,test}/**/*.rb"]
  s.files = files
  s.test_files = s.files.select {|path| path =~ /^test\/.*_test.rb/}

  s.require_paths = %w[lib]

  s.add_dependency "pg", "~> 0.14.1"
  s.add_dependency "scrolls", "~> 0.2.1"
end
