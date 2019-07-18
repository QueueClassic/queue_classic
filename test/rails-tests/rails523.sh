#!/bin/bash
set -e

rm -rf qctest523
gem install rails -v 5.2.3
rails new qctest523 --api --database=postgresql --skip-test-unit --skip-keeps --skip-spring --skip-sprockets --skip-javascript --skip-turbolinks

echo "1"

cd qctest523

bundle exec rails db:drop:all
bundle exec rails db:create
bundle exec rails db:migrate
bundle exec rails db:setup

echo "2"

echo "gem 'queue_classic', path: '../../../'" >> Gemfile
bundle install

echo "3"
bundle exec rails generate queue_classic:install
bundle exec rails db:migrate
