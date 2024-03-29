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
        join_associations = []

        recursive_add_association_to_joins = ->(current_reflection_or_klass:, table_alias:, assoc_reflection:, assoc_table_alias:){
          if assoc_reflection.belongs_to?
            join_on = "ON #{self.connection.quote_table_name(table_aliase)}.#{self.connection.quote_column_name(assoc_reflection.foreign_key)} = #{self.connection.quote_table_name(assoc_table_alias)}.#{self.connection.quote_column_name(assoc_reflection.primary_key)}"
          else
            join_on = "ON #{self.connection.quote_table_name(table_alias)}.#{self.connection.quote_column_name(assoc_reflection.primary_key)} = #{self.connection.quote_table_name(assoc_table_alias)}.#{self.connection.quote_column_name(assoc_reflection.foreign_key)}"
          end

          join_associations << "LEFT OUTER JOIN #{self.connection.quote_table_name(assoc_reflection.table_name)} AS #{assoc_table_alias} #{join_on}"

          if assoc_reflection.through_reflection
            recursive_add_association_to_joins.call(
              current_reflection_or_klass: assoc_reflection, 
              table_alias: assoc_table_alias,
              assoc_reflection: assoc_reflection.through_reflection,
              assoc_table_alias: "#{assoc_reflection.through_reflection.klass.table_name}_#{join_associations.size}",
            )
          end
        }
        
        recursive_add_to_sql_columns = ->(current_reflection_or_klass, attrs, table_alias:){
          if current_reflection_or_klass.class.name.start_with?("ActiveRecord::Reflection::")
            current_klass = current_reflection_or_klass.klass
          else
            current_klass = current_reflection_or_klass
          end

          if attrs.blank?
            ### Applies to String, Array and Hash
            attrs = nil
          end
          
          if attrs.is_a?(String) && current_klass.columns_hash[attrs]
            attrs = attrs.to_sym
          end

          case attrs.class.to_s
          when "Symbol"
            if current_klass.columns_hash[attrs.to_s].nil?
              raise ArgumentError.new("Attribute `:#{attrs}` not found on model #{current_klass.name}")
            end

            case current_klass.columns_hash[attrs.to_s].type.to_s
            when "string", "text"
              where_conditions << "(#{self.connection.quote_table_name(table_alias)}.#{self.connection.quote_column_name(attrs)} OPERATOR :search)"
            else
              where_conditions << "(CAST(#{self.connection.quote_table_name(table_alias)}.#{self.connection.quote_column_name(attrs)} AS CHAR) OPERATOR :search)"
            end
          when "String"
            where_conditions << "(#{attrs} OPERATOR :search)"
          when "Array"
            attrs.each_with_index do |x|
              recursive_add_to_sql_columns.call(current_reflection_or_klass, x) 
            end
          when "Hash"
            attrs.each do |assoc_name, inner_attrs|
              assoc_reflection = current_klass.reflect_on_all_associations.detect{|x| x.name.to_s == assoc_name.to_s}

              if assoc_reflection.nil?
                raise ArgumentError.new("Association '#{assoc_name}' not found on class '#{current_klass.name}'")
              end

              if inner_attrs.is_a?(Array)
                table_opts_hash = inner_attrs.delete{|x| x.is_a?(Hash) && x.has_key?(:table_alias) }
              end

              assoc_table_alias = table_opts_hash ? table_opts_hash[:table_alias] : assoc_reflection.klass.table_name

              if join_table_names.include?(assoc_table_alias)
                raise ArgumentError.new("Duplicate join table '#{assoc_table_alias}' found within search definition, please use the :table_alias option")
              end

              recursive_add_association_to_joins.call(
                current_reflection_or_klass: current_reflection_or_klass, 
                table_alias: table_alias,
                assoc_reflection: assoc_reflection,
                assoc_table_alias: assoc_table_alias,
              )

              recursive_add_to_sql_columns.call(assoc_reflection, inner_attrs, table_alias: join_table_alias) 
            end
          else
            raise ArgumentError.new("Invalid :attributes argument, #{attrs}")
          end
        }

        recursive_add_to_sql_columns.call(self, attributes, table_alias: self.table_name)

        where_conditions = where_conditions.join(" OR ")

        ### SET VALID COMPARISON OPERATORS
        valid_comparison_operators = ['LIKE', '=']

        case connection.adapter_name.downcase.to_s
        when "postgresql"
          valid_comparison_operators.unshift("ILIKE")
        end

        ### SET DEFAULT COMPARISON OPERATOR
        default_comparison_operator = valid_comparison_operators.first # default is ILIKE or LIKE

        ### CREATE THE SCOPE
        scope(scope_name, ->(search_str, search_type: "full_search", comparison_operator: default_comparison_operator, sql_variables: {}){
          if valid_comparison_operators.exclude?(comparison_operator)
            raise ArgumentError.new("Invalid argument for :comparison_operator. Valid options are: #{valid_comparison_operators}")
          end

          case search_type.to_s
          when "full_search"
            search_array = [search_str]
          when "multi_search"
            search_array = SearchArchitect.split_string_to_words(search_str)
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

          if !join_associations.empty?
            rel = rel.left_joins(*join_associations)
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
