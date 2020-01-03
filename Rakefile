require 'bundler/setup'

require 'yard'

YARD::Rake::YardocTask.new(:doc) do |t|
end

require 'bundler/gem_tasks'

require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.test_files = FileList['test/**/*_test.rb'].exclude('test/tmp/**/*')
  t.verbose = false
end

task default: :test
