require 'ostruct'

module MysqlRowGuard
  module SqlVariablesHashRefinement
    refine Hash do
      def to_sql
        self.to_s.gsub(':', '@').gsub('=>', ' := ').gsub(/[{}]/, '')
      end
    end
  end
end

using MysqlRowGuard::SqlVariablesHashRefinement

module MysqlRowGuard
  class Configuration
    TABLE_CALLBACK = '\k<table>'
    NAME = 'MysqlRowGuard'

    attr_reader :tables, :sql_variables
    def initialize
      @tables = []
      @sql_replacement = TABLE_CALLBACK
      @sql_variables = {}
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
      raise 'tables must be an array of table names' unless names.is_a? Array
      reset_cache
      @tables = names
    end

    def tables_hash
      @tables_hash ||= tables.each_with_object({}) do |table, hash|
        hash[table.to_s] = table.to_s.gsub(sql_pattern, sql_replacement)
      end
    end

    def sql_variables=(hash)
      raise 'sql_variables must be a hash' unless hash.is_a? Hash
      reset_cache
      @sql_variables = hash
    end

    def sql_replacement=(string)
      string = '%{table}' if String(string).empty?
      raise 'sql_replacement string must include "%{table}"' unless String(string).include?('%{table}')
      reset_cache
      @sql_replacement = string % { table: TABLE_CALLBACK }
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
