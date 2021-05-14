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
      :title, 
      :content
    ])

    Post.send(:search_scope, :search, attributes: [
      :title, 
      :content, 
      {
        comments: [:content]
      }
    ])

    Post.send(:search_scope, :search, attributes: [
      :title,
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
    Post.create!(title: "foo bar")
    Post.create!(title: "bar")
    assert Post.all.size > 2

    scope_name = "test_comparison_operators_1"

    Post.send(:search_scope, scope_name, attributes: [:title])

    assert_equal Post.send(scope_name, "bar", comparison_operator: "=").size, 1

    assert_equal Post.send(scope_name, "bar", comparison_operator: "LIKE").size, 2

    if defined?(PG)
      assert_equal Post.send(scope_name, "BAR", comparison_operator: "ILIKE").size, 2
    else
      assert_raise ArgumentError do
        Post.send(scope_name, "BAR", comparison_operator: "ILIKE")
      end
    end

    assert_raise ArgumentError do
      Post.send(scope_name, "BAR", comparison_operator: "foobar")
    end
  end

  def test_full_search
    Post.create!(title: "foo-bar-baz")
    assert Post.all.size > 1

    scope_name = "test_full_search"

    Post.send(:search_scope, scope_name, attributes: [:title])

    assert_equal Post.send(scope_name, "foo-bar", search_type: "full_search").size, 1
    assert_equal Post.send(scope_name, "foo bar", search_type: "full_search").size, 0
  end

  def test_multi_search
    Post.create!(title: "foo-bar-baz")
    assert Post.all.size > 1

    scope_name = "test_multi_search"

    Post.send(:search_scope, scope_name, attributes: [:title])

    assert_equal Post.send(scope_name, "foo-bar", search_type: "multi_search").size, 1
    assert_equal Post.send(scope_name, "foo bar", search_type: "multi_search").size, 1
  end

  def test_quoted_multi_searching
    # TODO
  end

end
