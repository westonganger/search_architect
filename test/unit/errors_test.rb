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
    Post.send(:search_scope, "foobar", attributes: [])
    Post.send(:search_scope, "foobar", attributes: [])
    Post.send(:search_scope, "foobar", attributes: [])

    valid = [
      "foobar",
      :foobar,
    ]

    valid.each do |x|
      assert Post.send(:search_scope, "foobar", attributes: [], sql_vars: [x])
    end

    invalid = [
      nil,
      1, 
      1.0, 
      BigDecimal(0),
      [], 
      {}, 
    ]

    invalid.each do |x|
      assert_raise ArgumentError do
        Post.send(:search_scope, "foobar", attributes: [], sql_vars: [x])
      end
    end
    
    ### RUNTIME
    # TODO
  end

  def test_attributes_validations
    ### DEFINITION
    valid = [
      "foobar", 
      :foobar,
    ]

    valid.each do |x|
      assert Post.send(:search_scope, "foobar", attributes: x)
    end

    invalid = [
      nil,
      "",
      1, 
      1.0, 
      BigDecimal(0),
      [], 
      {}, 
    ]

    invalid.each do |x|
      assert_raise ArgumentError do
        Post.send(:search_scope, "foobar", attributes: x)
      end
    end
  end

  def test_scope_name_validations
    ### DEFINITION
    valid_scope_names = [
      "foobar", 
      :foobar,
    ]

    valid_scope_names.each do |scope_name|
      assert Post.send(:search_scope, scope_name, attributes: [])
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
      Post.send(:search_scope, scope_name, attributes: [])
    end
  end

  def test_sql_variables_validations
    ### DEFINITION
    
    ### RUNTIME
  end

  def test_attributes_validations
    ### DEFINITION
    valid = [
      "foobar", 
      :foobar,
    ]

    valid.each do |x|
      assert Post.send(:search_scope, "foobar", attributes: x)
    end

    invalid = [
      nil,
      "",
      1, 
      1.0, 
      BigDecimal(0),
      [], 
      {}, 
    ]

    invalid.each do |x|
      assert_raise ArgumentError do
        Post.send(:search_scope, "foobar", attributes: x)
      end
    end
  end

  def test_comparison_operators_validations
    ### RUNTIME
    scope_name = "test_comparison_operators_1"

    assert Post.send(:search_scope, scope_name, attributes: [])

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
    ### RUNTIME
    scope_name = "test_search_type_validations"
    Post.send(:search_scope, scope_name, attributes: [])
    
    assert Post.send(scope_name, "foo-bar", search_type: "full_search").count

    assert Post.send(scope_name, "foo-bar", search_type: "multi_search").count

    assert_raise ArgumentError do
      Post.send(scope_name, "foo-bar", search_type: "foobar")
    end
  end

end
