require 'mysql_row_guard/sql_string_parser'

module MysqlRowGuard
  class SqlFortifier
    IGNORE_COMMANDS = %w[SHOW]
    def self.for(sql:, active_record: nil, configuration: MysqlRowGuard.configuration)
      # Only fortify once
      return sql if SqlFingerPrinter.stamped?(sql)

      # Don't use views for 'SHOW' commands since Table Views do not have primary keys
      # these commands are used by rails to get table definitions and primary keys for it's logic
      # make it think it's still accessing the original table
      # See: ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter#column_definitions
      # See: ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter#table_options
      # See: ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter#create_table_info
      #
      # Don't parse if the init_command is empty
      new_sql = if IGNORE_COMMANDS.include?(sql[0..3].upcase) || configuration.init_command.empty?
                  sql
                else
                  new(sql: sql, configuration: configuration).sql
                end

      SqlFingerPrinter.new(original_sql: sql, new_sql: new_sql, finger_print: configuration.init_command).sql do
        # optimization to only yield active directory command if query has changed
        yield(active_record) if active_record && block_given?
      end
    end

    attr_reader :original_sql, :configuration, :transformer
    def initialize(sql:, configuration: MysqlRowGuard.configuration)
      @original_sql = sql
      @configuration = configuration
      # @transformer = SqlStringParserTransformer.new(configuration: configuration)
      @transformer = SqlStringParser.new(tables: configuration.tables_hash)
    end

    def sql
      @sql ||= transformer.parse(original_sql)
    end
  end

  class SqlFingerPrinter
    attr_reader :original_sql, :new_sql, :finger_print
    def initialize(original_sql:, new_sql:, finger_print:)
      @original_sql = original_sql
      @new_sql = new_sql
      @finger_print = finger_print
    end

    def sql
      yield if modified_sql? && block_given?
      @sql ||= stamped_sql.extend(MysqlRowGuard::SqlFingerPrinter::Cached)
    end

    def modified_sql?
      new_sql != original_sql
    end

    def stamped_sql
      if modified_sql?
        "/* #{finger_print} */ #{new_sql}"
      else
        original_sql
      end
    end

    def self.stamped?(sql)
      sql.respond_to?(:mysql_row_guard_cached?)
    end
    
    module Cached
      def mysql_row_guard_cached?
        self
      end
    end
  end

end
