require 'active_record/mysql_row_level_security/sql_fortifier'
require 'active_record-mysql_row_level_security'

module ActiveRecord
  module MysqlRowLevelSecurity
    module ActiveRecordFortifier
      # Converts an arel AST to SQL
      def to_sql(arel, binds = [])
        sql = super(arel, binds)
        return sql unless ActiveRecord::MysqlRowLevelSecurity.enabled?
        fortify(sql)
      end

      def execute(sql, name = nil)
        return super(sql, name) unless ActiveRecord::MysqlRowLevelSecurity.enabled?
        begin
          fortified_sql = fortify(sql)
          super(fortified_sql, name)
        rescue fortified_exception => error
          original_sql = ActiveRecord::MysqlRowLevelSecurity::SqlFingerPrinter.original_sql(fortified_sql)
          if original_sql.empty?
            raise error
          else
            ActiveRecord::MysqlRowLevelSecurity.disable do
              ActiveRecord::MysqlRowLevelSecurity.configuration.error_callback.call(error)
              super(original_sql, name)
            end
          end
        end
      end

      def fortified_exception
        ::ActiveRecord::StatementInvalid
      end

      def fortify(sql)
        configuration = ActiveRecord::MysqlRowLevelSecurity.configuration
        fortified_sql = ActiveRecord::MysqlRowLevelSecurity::SqlFortifier.for(sql: sql, active_record: self) do |active_record|
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
end

if defined? ::ActiveRecord::ConnectionAdapters::Mysql2Adapter
  ::ActiveRecord::ConnectionAdapters::Mysql2Adapter.prepend ActiveRecord::MysqlRowLevelSecurity::ActiveRecordFortifier
end
