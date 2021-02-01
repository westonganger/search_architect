require "test_helper"

class SearchArchitectTest < ActiveSupport::TestCase

  setup do
  end

  teardown do
  end 

  def test_exposes_main_module
    assert SearchArchitect.is_a?(Module)

    assert !defined?(SearchArchitect)
  end

  def test_exposes_version
    assert SearchArchitect::VERSION
  end

  def test_provides_search_scope_method
    assert !SearchArchitect.respond_to?(:search_scope)

    assert SearchArchitect.private_methods.include?(:search_scope)

    assert_raises StandardError do
      SearchArchitect.send(:search_scope, [])
    end
  end

  def test_attributes
    assert_raises ArgumentError do
      Post.send(:search_scope, :search, attributes: false)
    end

    assert_raises ArgumentError do
      Post.send(:search_scope, :search, attributes: [[]])
    end

    assert_raises ArgumentError do
      Post.send(:search_scope, :search, attributes: [Object.new])
    end

    Post.send(:search_scope, :search, attributes: [
      :name, 
      :content
    ])

    Post.send(:search_scope, :search, attributes: [
      :name, 
      :content, 
      {
        comments: [:content]
      }
    ])

    Post.send(:search_scope, :search, attributes: [
      :name, 
      :content, 
      {
        comments: [
          :content, 
          user: [
            :first_name, 
            :last_name,
          ]
        ]
      }
    ])

    ### TODO incorrect association name
    assert_raises ArgumentError do
      Post.send(:search_scope, :search, attributes: [
        :name, 
        {
          foobar: []
        }
      ])
    end
  end

  def test_comparison_operators
    scope_name = "test_comparison_operators_1"
    Post.send(:search_scope, scope_name, attributes: [])

    assert_raises ArgumentError do
      Post.send(scope_name, "foo bar", comparison_operator: "asd")
    end

    case ActiveRecord::Base.connection.adapter_name.downcase.to_s
    when "postgresql"
      Post.send(scope_name, "foo bar", comparison_operator: "ILIKE")
    end

    Post.send(scope_name, "foo bar", comparison_operator: "LIKE")
    # TODO
    
    Post.send(scope_name, "foo bar", comparison_operator: "=")
    # TODO
  end

  def test_search_types
    scope_name = "test_search_types_1"
    Post.send(:search_scope, scope_name, attributes: [])

    assert_raises ArgumentError do
      Post.send(scope_name, "foo bar", search_type: "asd")
    end

    assert_raises ArgumentError do
      Post.send(scope_name, "foo bar", search_type: {})
    end

    #Post.send(scope_name, "foo bar") ### TODO test returns multi search

    Post.send(scope_name, "foo bar", search_type: "multi_search")

    Post.send(scope_name, "foo bar", search_type: "full_search")
  end

  def test_search_lifecycle
    # TODO
  end

end
