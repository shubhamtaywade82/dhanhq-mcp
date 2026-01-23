# frozen_string_literal: true

require "simplecov"

SimpleCov.start do
  add_filter "/spec/"
  add_filter "/bin/"
  add_filter "/exe/"
  enable_coverage :branch
  # TODO: Re-enable after PHASE 4
  # minimum_coverage line: 90, branch: 80
end

require "bundler/setup"
require "timecop"

require "support/dhanhq_stub"
require "support/fake_instrument"
require "support/instrument_stub"
require "dhanhq-mcp"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"
  config.order = :random

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
