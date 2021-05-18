module SearchArchitect
  module SearchScopeConcern
    extend ActiveSupport::Concern

    included do
      ### VALIDATES ACTIVE RECORD MODEL
      unless (self < ActiveRecord::Base)
        raise StandardError.new("Base class must be an ActiveRecord model")
      end
    end

    class_methods do
      private

      def search_scope(scope_name, sql_variables: [], attributes:)
        ### VALIDATE SCOPE NAME
        if scope_name.present? && [String, Symbol].include?(scope_name.class)
          scope_name = scope_name.to_s
        else
          raise ArgumentError.new("Scope name must be a String or Symbol")
        end

        ### VALIDATE SQL VARIABLES
        if sql_variables != nil
          if !sql_variables.is_a?(Array) || sql_variables.any?{|x| [Symbol, String].exclude?(x.class) }
            raise ArgumentError.new("Invalid :sql_variables argument. Must be an array of symbols or strings")
          else
            required_sql_variables = sql_variables.map{|x| x.to_s}.sort
          end
        end

        ### VALIDATE ATTRIBUTES
        recursive_validate_attributes = ->(attrs){
          if attrs.is_a?(Hash)
            attrs = attrs.values
          end

          if !attrs.is_a?(Array)
            raise ArgumentError.new("Invalid :attributes argument")
          elsif attrs.empty?
            raise ArgumentError.new("Invalid :attributes argument. Cannot be empty.")
          else
            attrs.each do |attr_entry|
              if attr_entry.is_a?(Hash)
                attr_entry.values.each do |v|
                  recursive_validate_attributes.call(v)
                end
              elsif [String, Symbol].include?(attr_entry.class)
                next
              else
                raise ArgumentError.new("Invalid :attributes argument")
              end
            end
          end
        }

        recursive_validate_attributes.call(attributes)

        ### GENERATE WHERE CONDITIONS AND LEFT JOINS
        where_conditions = []
        sql_joins = []

        recursive_add_association_to_joins = ->(current_reflection_or_klass:, assoc_reflection:){
          if current_reflection_or_klass.class.name.start_with?("ActiveRecord::Reflection::")
            table_alias = current_reflection_or_klass.name
          else
            table_alias = current_reflection_or_klass.table_name
          end

          if assoc_reflection.belongs_to?
            join_on = "ON #{table_alias}.#{assoc_reflection.association_foreign_key} = #{assoc_reflection.name}.#{assoc_reflection.association_primary_key}"
          else
            join_on = "ON #{table_alias}.#{assoc_reflection.association_primary_key} = #{assoc_reflection.name}.#{assoc_reflection.association_foreign_key}"
          end

          sql_joins << "LEFT OUTER JOIN #{assoc_reflection.table_name} AS #{assoc_reflection.name} #{join_on}"

          if assoc_reflection.through_reflection
            recursive_add_association_to_joins.call(
              current_reflection_or_klass: assoc_reflection, 
              assoc_reflection: assoc_reflection.through_reflection,
            )
          end
        }
        
        recursive_add_to_sql_columns = ->(current_reflection_or_klass, attrs){
          if current_reflection_or_klass.class.name.start_with?("ActiveRecord::Reflection::")
            current_klass = current_reflection_or_klass.klass
            table_alias = current_reflection_or_klass.name
          else
            current_klass = current_reflection_or_klass
            table_alias = current_klass.table_name
          end

          if attrs.class == Symbol
            where_conditions << "(#{table_alias}.#{attrs} OPERATOR :search)"
          elsif attrs.class == String
            where_conditions << "(#{attrs} OPERATOR :search)"
          elsif attrs.is_a?(Array)
            attrs.each do |x|
              recursive_add_to_sql_columns.call(current_klass, x) 
            end
          elsif attrs.is_a?(Hash)
            attrs.each do |assoc_name, inner_attrs|
              assoc_reflection = current_klass.reflect_on_all_associations.detect{|x| x.name.to_s == assoc_name.to_s}

              if assoc_reflection.nil?
                raise ArgumentError.new("Association '#{assoc_name}' not found on class '#{current_klass.name}'")
              end

              recursive_add_association_to_joins.call(
                current_reflection_or_klass: current_reflection_or_klass, 
                assoc_reflection: assoc_reflection,
              )

              recursive_add_to_sql_columns.call(assoc_reflection, inner_attrs) 
            end
          else
            raise ArgumentError.new("Invalid :attributes argument")
          end
        }

        recursive_add_to_sql_columns.call(self, attributes)

        where_conditions = where_conditions.join(" OR ")

        ### SET VALID COMPARISON OPERATORS
        valid_comparison_operators = ['LIKE', '=']

        case connection.adapter_name.downcase.to_s
        when "postgresql"
          valid_operators.unshift("ILIKE")
        end

        ### SET DEFAULT COMPARISON OPERATOR
        default_comparison_operator = valid_comparison_operators.first # default is ILIKE or LIKE

        ### CREATE THE SCOPE
        scope(scope_name, ->(search_str, search_type: "multi_search", comparison_operator: default_comparison_operator, sql_variables: {}){
          if valid_comparison_operators.exclude?(comparison_operator)
            raise ArgumentError.new("Invalid argument for :comparison_operator. Valid options are: #{valid_comparison_operators}")
          end

          case search_type
          when "full_search"
            search_array = [search_str]
          when "multi_search"
            ### SPLIT ON ALL WHITESPACE CHARACTERS
            orig_search_array = search_str.split(/\s/)

            search_array = []

            quote_char = '"'
            start_quote_item_index = nil

            ### HANDLE DOUBLE QUOTED SEARCH ITEMS WITH SPACES
            orig_search_array.each_with_index do |word, i|
              if start_quote_item_index.nil? && word.start_with?(quote_char)
                if word.end_with?(quote_char)
                  search_array << word[1..-2]
                else
                  start_quote_item_index = i
                end

              elsif start_quote_item_index
                if word.end_with?(quote_char)
                  search_array << orig_search_array[start_quote_item_index..i].join(" ")[1..-2]

                elsif (orig_search_array_size == i+1)
                  num = ((orig_search_array_size-1) - start_quote_item_index)

                  num.times do |i|
                    search_array << orig_search_array[i+start_quote_item_index]
                  end

                else
                  next
                end

              else
                search_array << word
              end
            end

          else
            raise ArgumentError.new("Invalid :search_type. Valid options are: [:multi_search, :full_search]")
          end

          ### VALIDATE REQUIRED SQL VARIABLES
          if sql_variables != nil
            if sql_variables.is_a?(Hash)
              if !(required_sql_variables - sql_variables.keys.collect(&:to_s)).empty?
                raise ArgumentError.new("Missing some :sql_variables keys. Requested variables are: #{required_sql_variables}")
              end
            else
              raise ArgumentError.new("Invalid :sql_variables argument. Must be a Hash")
            end
          end

          rel = self

          if !sql_joins.empty?
            rel = rel.joins(*sql_joins.uniq)
          end

          search_array.each do |q|
            ### SET SEARCH QUERY
            search_query = comparison_operator.include?("LIKE") ? "%#{q}%" : q

            rel = rel.where(
              where_conditions.gsub(" OPERATOR ", " #{comparison_operator} "),
              search: search_query,
              **sql_variables
            )
          end

          next rel
        }) ### END CREATE SCOPE

        return true
      end

    end

  end
end
