require 'ostruct'

module MysqlRowGuard
  class Configuration
    TABLE_CALLBACK = '\k<table>'
    NAME = 'MysqlRowGuard'

    def initialize
      @tables = []
      @sql_replacement = TABLE_CALLBACK
      @sql_variables = {}
    end

    def init_command
      return '' if @sql_variables.empty?
      variables = @sql_variables.to_s.gsub(':', '@').gsub('=>', ' := ').gsub(/[{}]/, '')
      @init_command ||= "SET #{variables}"
    end

    def sql_pattern
      return // if tables.empty?
      @pattern ||= Regexp.new(/\b(?<table>#{tables.join('|')})\b/i)
    end

    def tables=(names)
      raise 'sql_variables must be an array of table names' unless names.is_a? Array
      @pattern = nil # reset sql pattern
      @tables = names
    end

    def sql_variables=(hash)
      raise 'sql_variables must be a hash' unless hash.is_a? Hash
      @sql_variables = hash
    end

    def sql_replacement=(string)
      string = '%{table}' if String(string).empty?
      raise 'sql_replacement string must include "%{table}"' unless String(string).include?('%{table}')
      @sql_replacement = string % { table: TABLE_CALLBACK }
    end

    def sql_replacement
      return '' if sql_pattern == //
      @sql_replacement
    end

    def name
      NAME
    end

    private

    attr_reader :tables

  end
end
