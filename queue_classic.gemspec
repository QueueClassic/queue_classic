Gem::Specification.new do |s|
  s.name          = 'queue_classic'
  s.email         = 'ryan@heroku.com'
  s.version       = '0.2.4'
  s.date          = '2011-02-16'
  s.description   = "Queue Classic is an alternative queueing library for Ruby apps (Rails, Sinatra, Etc...) Queue Classic features asynchronous job polling, database maintained locks and no ridiculous dependencies. As a matter of fact, Queue Classic only requires the pg and json."
  s.summary       = s.description + "(simple)"
  s.authors       = ["Ryan Smith"]
  s.homepage      = "http://github.com/ryandotsmith/queue_classic"

  s.files       = %w[readme.md] + Dir["{lib,test}/**/*.rb"]
  s.test_files  = Dir["test/**/test_*.rb"]

  s.test_files = s.files.select {|path| path =~ /^test\/.*_test.rb/}
  s.require_paths = %w[lib]

  s.add_dependency 'pg', ">= 0.10.1"
  s.add_dependency 'json'
end
