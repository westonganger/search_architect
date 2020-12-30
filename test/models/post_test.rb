require "test_helper"

class SearchArchitectTest < Minitest::Test

  def test_attributes
    Post.send(:search_scope, :search, attributes: [
      :name, 
      :content
    ])

    Post.send(:search_scope, :search, attributes: [
      :name, 
      :content, {
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
    assert_raise ArgumentError do
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

    Post.send(scope_name, "foo bar", comparison_operator: "ILIKE")
    # TODO

    Post.send(scope_name, "foo bar", comparison_operator: "LIKE")
    # TODO
    
    Post.send(scope_name, "foo bar", comparison_operator: "=")
    # TODO
  end

  def test_search_types
    scope_name = "test_search_types_1"
    Post.send(:search_scope, scope_name, attributes: [])

    Post.send(scope_name, "foo bar", search_type: "multi_search")

    Post.send(scope_name, "foo bar", search_type: "full_search")
  end

  def test_search_lifecycle
    # TODO
  end

end
