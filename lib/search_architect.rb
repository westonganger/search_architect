require 'active_record'

require "search_architect/version"
require "search_architect/concerns/search_scope_concern.rb"

module SearchArchitect
  extend ActiveSupport::Concern

  included do
    include SearchArchitect::SearchScopeConcern
  end

  ### Split String into Words with Support for Single and Double Quotes
  ### https://stackoverflow.com/a/27742127/3068360
  def self.split_string_to_words(str)
    str
      .split(/\s(?=(?:[^'"]|'[^']*'|"[^"]*")*$)/)
      .select{|x| x.present? }
      .map{|x| x.gsub(/(^ +)|( +$)|(^["']+)|(["']+$)/, '')}
  end
end
