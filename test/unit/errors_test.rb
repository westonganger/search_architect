require "test_helper"

class ErrorsTest < ActiveSupport::TestCase

  setup do
  end

  teardown do
  end

  def test_model_validations
    Post.class_eval do
      include SearchArchitect
    end

    assert_raise StandardError do
      Array.class_eval do
        include SearchArchitect
      end
    end
  end

  def test_sql_variables_validations
    ### DEFINITION
    valid = [
      ["foobar"],
      [:foobar],
      nil,
      [],
    ]

    valid.each do |x|
      append_error_message " - #{x}" do
        assert Post.send(:search_scope, SecureRandom.hex(6), attributes: [:title], sql_variables: x)
      end
    end

    invalid = [
      "",
      1, 
      1.0, 
      BigDecimal(0),
      {}, 
      [1], 
      [nil], 
    ]

    invalid.each do |x|
      assert_raise ArgumentError do
        Post.send(:search_scope, SecureRandom.hex(6), attributes: [:title], sql_variables: x)
      end
    end
    
    ### RUNTIME
    scope_name = "test_sql_variables_validations"
    assert Post.send(:search_scope, SecureRandom.hex(6), attributes: [:title], sql_variables: [:test])

    assert_raise ArgumentError do
      assert Post.send(:search, scope_name, attributes: [:title], sql_variables: "test")
    end

    assert Post.send(:search, scope_name, sql_variables: {test: :foobar})
  end

  def test_attributes_validations
    ### DEFINITION
    
    valid = [
      "id", 
      :title,
      "CAST(number AS CHAR)", 
      "posts.content",
      "missing_attribute",
      "posts.missing_attribute",
    ]

    valid.each do |x|
      append_error_message " - #{x}" do
        assert Post.send(:search_scope, SecureRandom.hex(6), attributes: [x])
      end
    end

    invalid = [
      nil,
      "",
      1, 
      1.0, 
      BigDecimal(0),
      [], 
      {}, 
      :missing_attribute,
    ]

    invalid.each do |x|
      append_error_message " - #{x}" do
        assert_raise ArgumentError do
          Post.send(:search_scope, SecureRandom.hex(6), attributes: [x])
        end
      end
    end

    #### NESTED
    assert Post.send(:search_scope, SecureRandom.hex(6), attributes: [
      :title,
      :content, 
      {
        comments: [
          :content, 
          user: [
            :name, 
            :created_at,
          ]
        ]
      }
    ])

    assert_raise ArgumentError do
      Post.send(:search_scope, SecureRandom.hex(6), attributes: [
        :title,
        :content, 
        {
          comments: [
            user: [
              :missing_attribute, 
            ]
          ]
        }
      ])
    end

    assert_raise ArgumentError do
      Post.send(:search_scope, SecureRandom.hex(6), attributes: [
        :title,
        :content, 
        {
          comments: [
            user: [
              true, 
            ]
          ]
        }
      ])
    end
  end

  def test_scope_name_validations
    ### DEFINITION
    valid_scope_names = [
      SecureRandom.hex(6), 
      SecureRandom.hex(6).to_sym, 
    ]

    valid_scope_names.each do |scope_name|
      append_error_message " - #{scope_name}" do
        assert Post.send(:search_scope, scope_name, attributes: [:title])
      end
    end

    invalid_scope_names = [
      nil,
      "",
      1, 
      1.0, 
      BigDecimal(0),
      [], 
      {}, 
    ]

    invalid_scope_names.each do |scope_name|
      assert_raise ArgumentError do
        Post.send(:search_scope, scope_name, attributes: [:title])
      end
    end
  end

  def test_comparison_operators_validations
    scope_name = "test_comparison_operators_validations"

    assert Post.send(:search_scope, scope_name, attributes: [:title])

    ### RUNTIME
    assert Post.send(scope_name, "bar", comparison_operator: "=").count
    assert Post.send(scope_name, "bar", comparison_operator: "LIKE").count

    if defined?(PG)
      assert Post.send(scope_name, "bar", comparison_operator: "ILIKE").count
    else
      assert_raise ArgumentError do
        Post.send(scope_name, "bar", comparison_operator: "ILIKE")
      end
    end

    assert_raise ArgumentError do
      Post.send(scope_name, "bar", comparison_operator: "foobar")
    end
  end

  def test_search_types_validations
    scope_name = "test_search_type_validations"
    Post.send(:search_scope, scope_name, attributes: [:title])
    
    ### RUNTIME
    assert Post.send(scope_name, "foo-bar", search_type: "full_search").count

    assert Post.send(scope_name, "foo-bar", search_type: "multi_search").count

    assert_raise ArgumentError do
      Post.send(scope_name, "foo-bar", search_type: "foobar")
    end
  end

end
