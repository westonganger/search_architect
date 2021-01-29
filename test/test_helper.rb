#$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
ENV["RAILS_ENV"] = "test"

require "search_architect"

### Instantiates Rails
require File.expand_path("../dummy_app/config/environment.rb",  __FILE__)

require "rails/test_help"

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all
end

Rails.backtrace_cleaner.remove_silencers!

require 'minitest/reporters'
Minitest::Reporters.use!(
  Minitest::Reporters::DefaultReporter.new,
  ENV,
  Minitest.backtrace_filter
)

require "minitest/autorun"

# Run any available migration
if ActiveRecord.gem_version >= Gem::Version.new("6.0")
  ActiveRecord::MigrationContext.new(File.expand_path("dummy_app/db/migrate/", __dir__), ActiveRecord::SchemaMigration).migrate
elsif ActiveRecord.gem_version >= Gem::Version.new("5.2")
  ActiveRecord::MigrationContext.new(File.expand_path("dummy_app/db/migrate/", __dir__)).migrate
else
  ActiveRecord::Migrator.migrate File.expand_path("dummy_app/db/migrate/", __dir__)
end

DATA = {}.with_indifferent_access

DATA[:posts] = [
  Post.find_or_create_by!(number: 1, name: '', code: ''),
  Post.find_or_create_by!(number: 2, name: '', code: ''),
  Post.find_or_create_by!(number: 3, name: '', code: ''),
  Post.find_or_create_by!(number: 4, name: '', code: ''),
  Post.find_or_create_by!(number: 5, name: '', code: ''),
].shuffle
