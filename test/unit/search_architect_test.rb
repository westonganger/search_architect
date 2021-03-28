require "test_helper"

class SearchArchitectTest < ActiveSupport::TestCase

  setup do
  end

  teardown do
  end 

  def test_exposes_main_module
    assert SearchArchitect.is_a?(Module)
  end

  def test_exposes_version
    assert SearchArchitect::VERSION.is_a?(String)
  end

  def test_provides_search_scope_method
    assert SearchArchitect.methods.exclude?(:search_scope)
    assert SearchArchitect.private_methods.exclude?(:search_scope)

    assert Post.private_methods.include?(:search_scope)
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

  def test_default_comparison_operator
    if defined?(PG)
      Post.search("foobar").to_sql.include?(" ILIKE ")
    else
      Post.search("foobar").to_sql.include?(" LIKE ")
    end
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
    scope_name = "test_full_search"

    Post.send(scope_name, "foo bar", search_type: "full_search")
  end

  def test_multi_search
    scope_name = "test_multi_search"

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
