module SearchArchitect
  module SearchScopeConcern
    extend ActiveSupport::Concern

    class_methods do
      private

      def search_scope(scope_name, sql_variables: [], attributes:)
        ### VALIDATES ACTIVE RECORD MODEL
        unless (self < ActiveRecord::Base)
          raise StandardError.new("Base class must be an ActiveRecord model")
        end

        ### VALIDATE SCOPE NAME
        if [String, Symbol].include?(scope_name.class)
          scope_name = scope_name.to_s
        else
          raise ArgumentError.new("scope name must be a String or Symbol")
        end

        ### VALIDATE REQUIRED VARS
        if !sql_variables.is_a?(Array) || sql_variables.any?{|x| [Symbol, String].exclude?(x.class) }
          raise ArgumentError.new("Invalid :sql_variables argument. Must be an array of symbols or strings")
        else
          required_sql_variables = sql_variables.map{|x| x.to_s}.sort
        end

        ### VALIDATE ATTRIBUTES
        recursive_validate_attributes = ->(attrs){
          if attrs.is_a?(Hash)
            attrs = attrs.values
          end

          if !attrs.is_a?(Array)
            raise ArgumentError.new("Invalid :attributes argument, #{attr_entry.to_s}")
          else
            attrs.each do |attr_entry|
              if attr_entry.is_a?(Hash)
                attr_entry.values.each do |v|
                  recursive_validate_attributes.call(v)
                end
              elsif [String, Symbol].include?(attr_entry.class)
                next
              else
                raise ArgumentError.new("Invalid :attributes argument, #{attr_entry.to_s}")
              end
            end
          end
        }

        recursive_validate_attributes.call(attributes)

        ### GENERATE WHERE CONDITIONS AND LEFT JOINS
        where_conditions = []
        sql_joins = []
        
        recursive_add_to_sql_columns = ->(table_alias, attrs, current_klass){
          table_alias = table_alias.to_s

          attrs.each do |attr_entry|
            if attrs.is_a?(Hash)
              attrs.each do |assoc_name, inner_attrs|
                assoc_reflection = current_klass.reflect_on_all_associations.detect{|x| x.name.to_s == table_alias}

                if assoc_reflection.nil?
                  raise ArgumentError.new("Association '#{table_alias.to_sym}' not found on class '#{current_klass.name}'")
                end

                if assoc_reflection.belongs_to?
                  if assoc_reflection.through_reflection
                    # TODO
                  else
                    join_on = "ON #{current_table_name}.#{assoc_reflection.foreign_key} = #{assoc_reflection.klass.table_name}.id"

                    sql_joins << "LEFT OUTER JOIN #{assoc_reflection.table_name} AS #{assoc_name} #{join_on}"
                  end

                elsif ['HasOne','HasMany'].include?(assoc_reflection.association_class.name)
                  if assoc_reflection.through_reflection
                    # TODO
                  else
                    join_on = "ON #{current_table_name}.id = #{assoc_reflection.klass.table_name}.#{assoc_reflection.foreign_key}"

                    sql_joins << "LEFT OUTER JOIN #{assoc_reflection.table_name} AS #{assoc_name} #{join_on}"
                  end

                else
                  raise ArgumentError.new("Unsupported Association Type: #{assoc_reflection.type}")
                end

                recursive_add_to_sql_columns.call(assoc_name, inner_attrs, current_klass) 
              end
            else
              where_conditions << "(#{table_alias}.#{attr_entry} :comparison_operator :search)"
            end
          end
        }

        recursive_add_to_sql_columns.call(self.table_name, attributes, self)

        where_conditions = where_conditions.join(" OR ")

        ### SET VALID OPTION TYPES
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
            search_terms = [search_str]
          when "multi_search"
            ### Split on spaces but handle string quoting (one level deep only)
            search_terms = []

            wait_for_quote_type = nil

            start_index = 0

            search_str.chars.each_with_index do |char, i|
              if char == '"'
                # Double Quotes
                if wait_for_quote_type == '"'
                  search_terms << search_str[start_index..i-1]
                  start_index = i+1
                  wait_for_quote_type = nil
                else
                  wait_for_quote_type = '"'
                end

              elsif char == "'"
                # Single Quotes
                if wait_for_quote_type == "'"
                  search_terms << search_str[start_index..i-1]
                  start_index = i+1
                  wait_for_quote_type = nil
                else
                  wait_for_quote_type = "'"
                end

              elsif char =~ /\s/
                # Whitespace
                search_terms << search_str[start_index..i-1]
                start_index = i+1
              end
            end

          else
            raise ArgumentError.new("Invalid :search_type. Valid options are: [:multi_search, :full_search]")
          end

          if sql_variables.is_a?(Hash)
            given_variables = sql_variables.keys.map{|x| x.to_s}.sort

            if given_variables != required_sql_variables
              raise ArgumentError.new("Missing some :sql_variables keys. Requested variables are: #{required_sql_variables}")
            end
          else
            raise ArgumentError.new("Invalid :sql_variables argument. Must be a Hash")
          end

          rel = self

          if !sql_joins.empty?
            rel = rel.uniq.joins(*sql_joins)
          end

          search_terms.each do |q|
            if valid_comparison_operators.include?(comparison_operator)
              ### SET SEARCH QUERY
              search_query = comparison_operator.include?("LIKE") ? "%#{q}%" : q
            end

            rel = rel.where(
              where_conditions, 
              comparison_operator: comparison_operator, 
              search: search_query,
              **sql_variables
            )
          end

          next rel
        })
      end

    end

  end
end
