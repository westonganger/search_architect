require File.expand_path(File.dirname(__FILE__) + '/lib/search_architect/version.rb')

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task default: [:test]

task :console do
  require 'search_architect'

  ### Instantiates Rails
  require './test/dummy_app/config/environment.rb'

  ### Require ApplicationRecord
  require './test/dummy_app/app/models/application_record'

  ### Require all test app models
  Dir["./test/dummy_app/app/models/*.rb"].each{|file| require file }

  require './test/migrate_and_seed'

  require 'irb'
  binding.irb
end
