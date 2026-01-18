# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in dhanhq-mcp.gemspec
gemspec

# DhanHQ client
gem "DhanHQ", git: "https://github.com/shubhamtaywade82/dhanhq-client.git", branch: "main"

gem "irb"
gem "rake", "~> 13.0"

gem "simplecov", require: false

gem "rubocop", "~> 1.21"
gem "rubocop-performance", require: false
gem "rubocop-rake", require: false
gem "rubocop-rspec", require: false

gem "rackup", require: false
gem "webrick", require: false
gem "yard", require: false

group :test do
  gem "rspec"
  gem "timecop"
end
