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

    assert Post.respond_to?(:search_scope)
  end

  def test_attributes
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
  end

  def test_comparison_operators
    scope_name = "test_comparison_operators_1"
    Post.send(:search_scope, scope_name, attributes: [])

    Post.send(scope_name, "foo bar", comparison_operator: "LIKE")
    # TODO
    
    Post.send(scope_name, "foo bar", comparison_operator: "=")
    # TODO
  end

  def test_full_search
    Post.send(scope_name, "foo bar", search_type: "full_search")
  end

  def test_multi_search
    Post.send(scope_name, "foo bar") ### TODO test returns multi search

    Post.send(scope_name, "foo bar", search_type: "multi_search")
  end

  def test_quoted_multi_searching
    # TODO
  end

  def test_search_lifecycle
    # TODO
  end

end
