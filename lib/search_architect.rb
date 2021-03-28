require 'active_record'

require "search_architect/version"
require "search_architect/concerns/search_scope_concern.rb"

module SearchArchitect
  extend ActiveSupport::Concern

  included do
    include SearchArchitect::SearchScopeConcern
  end
end
