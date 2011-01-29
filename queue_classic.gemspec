Gem::Specification.new do |s|
  s.name          = 'queue_classic'
  s.email         = 'ryan@heroku.com'
  s.version       = '0.1.0'
  s.date          = '2011-01-28'
  s.description   = "Job Queue for Ruby"
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
