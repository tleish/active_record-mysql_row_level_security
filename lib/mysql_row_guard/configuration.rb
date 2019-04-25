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
    DEFAULT_TABLE_CALLBACK = '\k<table>'
    NAME = 'MysqlRowGuard'

    attr_reader :tables, :sql_variables, :error_callback
    def initialize
      @tables = []
      @sql_replacement = DEFAULT_TABLE_CALLBACK
      @sql_variables = {}
      @error_callback = Proc.new {}
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
      return if @sql_variables == regex_callback
      raise 'sql_replacement string must be empty or include "\k<table>"' unless String(regex_callback).include?('\k<table>')
      reset_cache
      @sql_replacement = regex_callback
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
