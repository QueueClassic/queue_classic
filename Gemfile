# frozen_string_literal: true

source 'https://rubygems.org' do
  gem 'rake'

  gemspec

  group :development do
    gem 'rubocop'
  end

  group :development, :test do
    gem 'activerecord', '>= 5.0.0', '< 6.1'
  end

  group :test do
    gem 'minitest', '~> 5.8'
    gem 'minitest-reporters'
  end
end
