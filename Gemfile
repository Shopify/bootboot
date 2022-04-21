# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gemspec

gem "rubocop-shopify", require: false

group :deployment do
  gem "package_cloud"
  gem "rake"
end

group :test do
  gem "rubocop"
end
