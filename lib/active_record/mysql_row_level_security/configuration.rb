require 'ostruct'

module ActiveRecord
  module MysqlRowLevelSecurity
    module SqlVariablesHashRefinement
      refine Hash do
        def to_sql
          self.to_s.gsub(':', '@').gsub('=>', ' := ').gsub(/[{}]/, '')
        end
      end
    end
  end
end

using ActiveRecord::MysqlRowLevelSecurity::SqlVariablesHashRefinement

module ActiveRecord
  module MysqlRowLevelSecurity
    class Configuration
      DEFAULT_TABLE_CALLBACK = '\k<table>'
      SKIP_QUERIES_REGEX = /USE INDEX/i
      DEFAULT_QUERY_TYPES = %w[SELECT]
      NAME = 'MysqlRowLevelSecurity'

      attr_reader :tables, :sql_variables, :error_callback, :query_types_regex
      def initialize
        @tables = []
        @sql_replacement = DEFAULT_TABLE_CALLBACK
        @sql_variables = {}
        @error_callback = Proc.new { }
      end

      def reset_cache
        @pattern = nil
        @tables_hash = nil
        @init_command = nil
      end

      def init_command
        return '' if @sql_variables.empty?
        @init_command ||= "SET #{@sql_variables.to_sql}"
      end

      def sql_pattern
        return // if tables.empty?
        @pattern ||= Regexp.new(/\b(?<table>#{tables.join('|')})\b/i)
      end

      def tables=(names)
        return if @tables == names
        raise 'tables must be an array of table names' unless names.is_a? Array
        reset_cache
        @tables = names
      end

      def tables_hash
        @tables_hash ||= tables.each_with_object({}) do |table, hash|
          hash[table.to_s] = table.to_s.gsub(sql_pattern, sql_replacement) unless sql_replacement == DEFAULT_TABLE_CALLBACK
        end
      end

      def sql_variables=(hash)
        return if @sql_variables == hash
        raise 'sql_variables must be a hash' unless hash.is_a? Hash
        reset_cache
        @sql_variables = hash
      end

      def sql_replacement=(regex_callback = DEFAULT_TABLE_CALLBACK)
        regex_callback = DEFAULT_TABLE_CALLBACK if regex_callback.empty?
        return if @sql_replacement == regex_callback
        raise 'sql_replacement string must be empty or include "\k<table>"' unless regex_callback.include?('\k<table>')
        reset_cache
        @sql_replacement = regex_callback
      end

      def query_types_match?(query)
        self.query_types = DEFAULT_QUERY_TYPES unless query_types_regex
        !!(query =~ query_types_regex) && !(query =~ SKIP_QUERIES_REGEX)
      end

      def query_types=(types)
        return if @query_types == types
        @query_types = types
        @query_types_regex = Regexp.new(/^#{types.join('|')}/i)
      end

      def error(&block)
        @error_callback = block
      end

      def sql_replacement
        return '' if sql_pattern == //
        @sql_replacement
      end

      def name
        NAME
      end
    end
  end
end
