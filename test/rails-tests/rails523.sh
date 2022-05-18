#!/bin/bash
set -e

# remove any old folder, should only matter locally
rm -rf qctest523

# install rails but not with much stuff
gem install rails -v 5.2.3
rails new qctest523 --api --database=postgresql --skip-test-unit --skip-keeps --skip-spring --skip-sprockets --skip-javascript --skip-turbolinks
cd qctest523

echo "DATABASE URL: $DATABASE_URL"

# get the db setup, run any default migrations
bundle install
bundle exec rails db:drop:all
bundle exec rails db:create
bundle exec rails db:migrate
bundle exec rails db:setup

# install qc --> gem file, bundle, add ourselves and migrate.
echo "gem 'queue_classic', path: '../../../'" >> Gemfile
bundle install
bundle exec rails generate queue_classic:install
bundle exec rails db:migrate
