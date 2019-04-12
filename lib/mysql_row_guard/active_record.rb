require 'mysql_row_guard'

module MysqlRowGuard
  module ActiveRecord
    # Converts an arel AST to SQL
    def to_sql(arel, binds = [])
      sql = super(arel, binds)
      MysqlRowGuard::SqlFortifier.for(sql: sql)
    end

    def execute(sql, name = nil)
      ensure_mysql_row_guard_variables
      fortified_sql = MysqlRowGuard::SqlFortifier.for(sql: sql)
      super(fortified_sql, name)
    end

    def ensure_mysql_row_guard_variables
      init_command = MysqlRowGuard.configuration.init_command
      # already set?
      return if @connection.query_options[:init_command] == init_command
      # ensure variable is set in case connection is reset
      @connection.query_options[:init_command] = init_command
      # set variable on MySQL now unless empty
      execute(init_command, MysqlRowGuard.configuration.name) unless init_command.empty?
    end
  end
end

if defined? ::ActiveRecord
  require 'active_record/connection_adapters/mysql2_adapter'
  ::ActiveRecord::ConnectionAdapters::Mysql2Adapter.prepend MysqlRowGuard::ActiveRecord
end