#$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
ENV["RAILS_ENV"] = "test"

require "search_architect"

begin
  require 'warning'

  Warning.ignore(
    %r{mail/parsers/address_lists_parser}, ### Hide mail gem warnings
  )
rescue LoadError
  # Do nothing
end

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

############################################################### MIGRATIONS AND DATA
if ActiveRecord.gem_version >= Gem::Version.new("6.0")
  ActiveRecord::MigrationContext.new(File.expand_path("dummy_app/db/migrate/", __dir__), ActiveRecord::SchemaMigration).migrate
elsif ActiveRecord.gem_version >= Gem::Version.new("5.2")
  ActiveRecord::MigrationContext.new(File.expand_path("dummy_app/db/migrate/", __dir__)).migrate
else
  ActiveRecord::Migrator.migrate File.expand_path("dummy_app/db/migrate/", __dir__)
end

[Post].each do |klass|
  if defined?(SQLite3)
    ActiveRecord::Base.connection.execute("DELETE FROM #{klass.table_name};")
    ActiveRecord::Base.connection.execute("UPDATE `sqlite_sequence` SET `seq` = 0 WHERE `name` = '#{klass.table_name}';")
  else
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{klass.table_name}")
  end
end

DATA = {}.with_indifferent_access

DATA[:posts] = [
  Post.find_or_create_by!(title: 1, content: 3),
  Post.find_or_create_by!(title: 2, content: 2),
  Post.find_or_create_by!(title: 3, content: 2),
  Post.find_or_create_by!(title: 4, content: 1),
  Post.find_or_create_by!(title: 5, content: 1),
].shuffle

############################################################### HELPER METHODS
def append_error_message(msg, &block)
  exceptions = [
    #RSpec::Expectations::ExpectationNotMetError,
    #Capybara::ElementNotFound,
    Minitest::Assertion,
  ]

  begin
    block.call
  rescue *exceptions => e
    e.message << "\n#{msg}"

    raise e
  end
end
