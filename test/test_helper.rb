Warning[:deprecated] = true if Warning.respond_to?(:[]=)

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require_relative "../test/dummy/config/environment"
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../test/dummy/db/migrate", __dir__)]
require "rails/test_help"

Rails.backtrace_cleaner.add_filter{|line| line.sub("#{File.dirname(__dir__)}/", "") }

ActiveSupport::TestCase.fixtures :all
