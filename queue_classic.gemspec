Gem::Specification.new do |s|
  s.name          = 'queue_classic'
  s.email         = 'ryan@heroku.com'
  s.version       = '0.1.3'
  s.date          = '2011-01-28'
  s.description   = "Queue Classic is an alternative queueing library for Ruby apps (Rails, Sinatra, Etc...) Queue Classic features __asynchronous__ job polling, database maintained locks and no ridiculous dependencies. As a matter of fact, Queue Classic only requires the __pg__ and __json__."
  s.summary       = s.description + "(simple)"
  s.authors       = ["Ryan Smith"]
  s.homepage      = "http://github.com/ryandotsmith/Queue-Classic"

  s.files       = %w[readme.markdown] + Dir["{lib,test}/**/*.rb"]
  s.test_files  = Dir["test/**/test_*.rb"]

  s.test_files = s.files.select {|path| path =~ /^test\/.*_test.rb/}
  s.require_paths = %w[lib]

  s.add_dependency 'pg'
  s.add_dependency 'json'
end
