Gem::Specification.new do |s|
  s.name          = 'queue_classic'
  s.email         = 'ryan@heroku.com'
  s.version       = '1.0.0'
  s.date          = '2011-08-22'
  s.description   = "queue_classic is a queueing library for Ruby apps. (Rails, Sinatra, Etc...) queue_classic features asynchronous job polling, database maintained locks and no ridiculous dependencies. As a matter of fact, queue_classic only requires pg."
  s.summary       = "postgres backed queue"
  s.authors       = ["Ryan Smith"]
  s.homepage      = "http://github.com/ryandotsmith/queue_classic"

  s.files         = %w[readme.md] + Dir["{lib,test}/**/*.rb"]
  s.test_files    = s.files.select {|path| path =~ /^test\/.*_test.rb/}

  s.require_paths = %w[lib]

  s.add_dependency 'pg', "~> 0.11.0"
  s.add_dependency 'json', "~> 1.6.1"
end
