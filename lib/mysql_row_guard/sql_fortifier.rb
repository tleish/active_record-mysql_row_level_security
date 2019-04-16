module MysqlRowGuard
  class SqlFortifier
    def self.for(sql:, active_record: nil, configuration: MysqlRowGuard.configuration)
      yield(active_record) if active_record && block_given?

      # Only fortify once
      return sql if sql.respond_to?(:mysql_row_guard_cached?)

      # Only fortify once
      return sql if sql.respond_to?(:mysql_row_guard_cached?)

      # Don't use views for 'SHOW' commands since Table Views do not have primary keys
      # these commands are used by rails to get table definitions and primary keys for it's logic
      # make it think it's still accessing the original table
      # See: ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter#column_definitions
      # See: ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter#table_options
      # See: ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter#create_table_info
      #
      # Don't parse if the init_command is empty
      new_sql = if sql[0..3].upcase == 'SHOW' || configuration.init_command.empty?
                  sql
                else
                  new(sql: sql, configuration: configuration).sql
                end
      new_sql.extend(MysqlRowGuard::SqlFortifier::Cached)
    end

    attr_reader :original_sql, :configuration
    def initialize(sql:, configuration: MysqlRowGuard.configuration)
      @original_sql = sql
      @configuration = configuration
    end

    def sql
      @sql ||= SqlFingerPrinter.for(original_sql: original_sql, new_sql: new_sql, finger_print: configuration.init_command)
    end

    def new_sql
      original_sql.gsub(configuration.sql_pattern, configuration.sql_replacement)
    end

    module Cached
      def mysql_row_guard_cached?
        self
      end
    end
  end

  class SqlFingerPrinter
    def self.for(original_sql:, new_sql:, finger_print:)
      if new_sql == original_sql
        original_sql
      else
        "/* #{finger_print} */ #{new_sql}"
      end
    end
  end

end
