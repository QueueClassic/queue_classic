#!/bin/bash
set -e
export BUNDLE_GEMFILE=Gemfile523

rm -rf qctest523
bundle exec rails new qctest523 --api --database=postgresql --skip-test-unit --skip-keeps --skip-spring --skip-sprockets --skip-javascript --skip-turbolinks

unset BUNDLE_GEMFILE

cd qctest523

bundle exec rails db:drop:all
bundle exec rails db:create
bundle exec rails db:migrate
bundle exec rails db:setup

echo "gem 'queue_classic', path: '../../../'" >> Gemfile

bundle exec rails generate queue_classic:install
bundle exec rails db:migrate