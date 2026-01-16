# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"

RuboCop::RakeTask.new

begin
  require "yard"
  YARD::Rake::YardocTask.new(:doc) do |task|
    task.files = ["lib/**/*.rb"]
    task.options = ["--output-dir", "doc/yard", "--markup", "markdown"]
  end
rescue LoadError
  # YARD not available
end

task default: %i[spec rubocop]
