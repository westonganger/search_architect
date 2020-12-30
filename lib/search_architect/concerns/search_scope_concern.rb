module SearchArchitect
  module SearchScopeConcern
    extend ActiveSupport::Concern

    class_methods do
      private

      def search_scope(scope_name, attributes:)
        ### VALIDATE SCOPE NAME
        if [String, Symbol].include?(scope_name.class)
          scope_name = scope_name.to_s
        else
          raise ArgumentError.new("scope name must be a String or Symbol")
        end

        ### VALIDATE ATTRIBUTES
        recursive_validate_attributes = ->(attrs){
          if !attrs.is_a?(Array)
            raise ArgumentError.new("Invalid :attributes argument")
          else
            attrs.each do |attr_entry|
              if attr_entry.is_a?(Hash)
                recursive_validate_attributes.call(attr_entry)
              elsif [String, Symbol, Hash, HashWithIndifferentAccess].include?(attr_entry.class)
                next
              else
                raise ArgumentError.new("Invalid :attributes argument")
              end
            end
          end
        }

        recursive_validate_attrs.call(attributes)

        ### GENERATE WHERE CONDITIONS AND LEFT JOINS
        where_conditions = []
        left_joins = []
        
        recursive_add_to_sql_columns = ->(table_alias, attrs){
          table_alias = table_alias.to_s

          attrs.each do |attr_entry|
            if attrs.is_a?(Hash)
              attrs.each do |assoc_name, inner_attrs|
                assoc_reflection = self.reflect_on_all_associations.detect{|x| x.name.to_s == table_alias}

                case assoc_reflection.type.to_s
                when "belongs_to"
                  join_on = "ON #{current_table_name}.#{}"
                when "has_and_belongs_to_many"
                  join_on = ""
                else
                  join_on = "ON #{current_table_name}. = #{assoc_name}.#{}"
                end

                sql_joins << "LEFT OUTER JOIN #{assoc_reflection.table_name} AS #{assoc_name} #{join_on}"

                recursive_add_to_sql_columns.call(assoc_name, inner_attrs) 
              end
            else
              where_conditions << "#{table_alias}.#{attr_entry} :comparison_operator :search"
            end
          end
        }

        recursive_add_to_sql_columns.call(self.table_name, attributes)

        where_conditions = where_conditions.join(" OR ")

        ### SET VALID OPTION TYPES
        valid_search_types = ["multi_search", "full_search"]

        valid_comparison_operators = ['LIKE', '=']

        case connection.adapter_name.downcase.to_s
        when "postgresql"
          valid_operators.unshift("ILIKE")
        end

        ### SET DEFAULT COMPARISON OPERATOR
        default_comparison_operator = valid_comparison_operators.first # default is ILIKE or LIKE

        ### SET SEARCH QUERY
        search_query = comparison_operator.include?("LIKE") ? "%#{search_str}%" : search_str

        ### CREATE THE SCOPE
        scope(scope_name) do |search_str, search_type: "multi_search", comparison_operator: default_comparison_operator|
          if valid_comparison_operators.exclude?(comparison_operator)
            raise ArgumentError.new("Invalid argument for :comparison_operator. Valid options are: #{valid_comparison_operators}")
          end

          if valid_search_types.exclude?(search_type.to_s)
            raise ArgumentError.new("Invalid :search_type. Valid options are: #{valid_search_types}")
          end

          self.joins(*left_joins).where(where_conditions, comparison_operator: comparison_operator, search: search_query)
        end
      end

    end

  end
end
