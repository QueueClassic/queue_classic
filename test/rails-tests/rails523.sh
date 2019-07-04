#!/bin/bash
set -e

rm -rf qctest523
bundle exec rails new qctest523 --api --database=postgresql --skip-test-unit --skip-keeps --skip-spring --skip-sprockets --skip-javascript --skip-turbolinks

cd qctest523

rails db:drop:all
rails db:create
rails db:migrate
rails db:setup

echo "gem 'queue_classic', path: '../../../'" >> Gemfile

rails generate queue_classic:install
bundle exec rake db:migrate