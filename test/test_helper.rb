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

require 'migrate_and_seed'

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
