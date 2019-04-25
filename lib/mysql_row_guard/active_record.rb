require 'mysql_row_guard'



module MysqlRowGuard
  module ActiveRecord
    # Converts an arel AST to SQL
    def to_sql(arel, binds = [])
      sql = super(arel, binds)
      return sql unless MysqlRowGuard.enabled?
      fortify(sql)
    end

    def execute(sql, name = nil)
      return super(sql, name) unless MysqlRowGuard.enabled?
      begin
        fortified_sql = fortify(sql)
        super(fortified_sql, name)
      rescue ::ActiveRecord::StatementInvalid => error
        original_sql = MysqlRowGuard::SqlFortifier.original_sql(fortified_sql)
        if original_sql.empty?
          raise error
        else
          MysqlRowGuard.disable do
            MysqlRowGuard.configuration.error_callback(error)
            super(original_sql, name)
          end
        end
      end
    end

    def fortify(sql)
      configuration = MysqlRowGuard.configuration
      fortified_sql = MysqlRowGuard::SqlFortifier.for(sql: sql, active_record: self) do |active_record|
        active_record.ensure_mysql_row_guard_variables(configuration)
      end
      fortified_sql
    end

    def ensure_mysql_row_guard_variables(configuration)
      init_command = configuration.init_command
      # already set?
      return if @connection.query_options[:init_command] == init_command
      # ensure variable is set in case connection is reset
      @connection.query_options[:init_command] = init_command
      # set variable on MySQL now unless empty
      execute(init_command, configuration.name) unless init_command.empty?
    end
  end
end

if defined? ::ActiveRecord
  require 'active_record/connection_adapters/mysql2_adapter'
  ::ActiveRecord::ConnectionAdapters::Mysql2Adapter.prepend MysqlRowGuard::ActiveRecord
end
