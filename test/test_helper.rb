# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require_relative "../test/dummy/config/environment"
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../test/dummy/db/migrate", __dir__)]
require "rails/test_help"

Rails.backtrace_cleaner.remove_silencers!
Rails.backtrace_cleaner.add_silencer{|line| !line.include?(File.basename(File.dirname(__dir__))) }

# Filter out Minitest backtrace while allowing backtrace from other libraries
# to be shown.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new

require "rails/test_unit/reporter"
Rails::TestUnitReporter.executable = "rake test"

ActiveSupport::TestCase.fixtures :all
