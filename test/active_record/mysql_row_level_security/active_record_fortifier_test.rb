require 'test_helper'
require 'active_record-mysql_row_level_security'
require 'ostruct'

module ActiveRecord
  module MysqlRowLevelSecurity
    class ActiveRecordFake
      attr_reader :connection
      def initialize
        @connection = OpenStruct.new(query_options: {})
      end

      def execute(sql, name = nil)
        [sql, name]
      end

      def to_sql(arel, binds = [])
        arel
      end
    end
    ActiveRecord::MysqlRowLevelSecurity::ActiveRecordFake.prepend ActiveRecord::MysqlRowLevelSecurity::ActiveRecordFortifier


    class FakeError < StandardError; end

    class ActiveRecordExceptionFake < ActiveRecord::MysqlRowLevelSecurity::ActiveRecordFake
      def execute(sql, name = nil)
        raise ActiveRecord::MysqlRowLevelSecurity::FakeError if sql.empty?
        super(sql, name)
      end
    end

    module StatementInvalidFake
      def fortified_exception
        ActiveRecord::MysqlRowLevelSecurity::FakeError
      end
    end
    ActiveRecord::MysqlRowLevelSecurity::ActiveRecordExceptionFake.prepend ActiveRecord::MysqlRowLevelSecurity::ActiveRecordFortifier
    ActiveRecord::MysqlRowLevelSecurity::ActiveRecordExceptionFake.prepend ActiveRecord::MysqlRowLevelSecurity::StatementInvalidFake

  end
end


describe ActiveRecord::MysqlRowLevelSecurity::ActiveRecordFortifier do
  let(:mysql_client) { ActiveRecord::MysqlRowLevelSecurity::ActiveRecordFake.new }

  describe '#execute' do
    it 'does not modify a query' do
      ActiveRecord::MysqlRowLevelSecurity.configure do |configuration|
        configuration.tables = %w[books comments]
      end
      ActiveRecord::MysqlRowLevelSecurity.configuration.sql_replacement = '\k<table>'
      original_sql = 'SELECT * FROM books, comments'
      modified_sql, name = mysql_client.execute(original_sql, 'my name')
      assert_equal original_sql, modified_sql
      assert_equal 'my name', name
    end

    it 'returns a configuration with a view' do
      ActiveRecord::MysqlRowLevelSecurity.configure do |configuration|
        configuration.tables = %w[fortune teller]
        configuration.sql_replacement = 'my_\k<table>_view'
        configuration.sql_variables = { my_var: 1 }
      end
      original_sql = 'SELECT * FROM fortune, teller'
      modified_sql, _ = mysql_client.execute(original_sql)
      assert_equal '/* SET @my_var := 1 */ SELECT * FROM my_fortune_view, my_teller_view', modified_sql
    end

    it 'raises an error when sql is bad' do
      error = nil
      ActiveRecord::MysqlRowLevelSecurity.configure do |configuration|
        configuration.tables = %w[fortune teller]
        configuration.sql_replacement = 'my_\k<table>_view'
        configuration.sql_variables = { my_var: 1 }
        configuration.error { |error| error }
      end
      mysql_client = ActiveRecord::MysqlRowLevelSecurity::ActiveRecordExceptionFake.new
      exception = assert_raises ActiveRecord::MysqlRowLevelSecurity::FakeError do
        modified_sql, _ = mysql_client.execute('')
      end
    end

    it 're-executes original sql if error' do
      error = nil
      ActiveRecord::MysqlRowLevelSecurity.configure do |configuration|
        configuration.tables = %w[fortune teller]
        configuration.sql_replacement = 'my_\k<table>_view'
        configuration.sql_variables = { my_var: 1 }
        configuration.error { |error| error }
      end
      mysql_client = ActiveRecord::MysqlRowLevelSecurity::ActiveRecordExceptionFake.new
      original_sql = 'SELECT * FROM fortune, teller'
      sql = ''
      sql.define_singleton_method(:original_sql) { original_sql }
      modified_sql, _ = mysql_client.execute(sql)
      assert_equal '/* SET @my_var := 1 */ SELECT * FROM my_fortune_view, my_teller_view', modified_sql
    end

    it 'calls custom configuration error before SQL error retry' do
      error = nil
      ActiveRecord::MysqlRowLevelSecurity.configure do |configuration|
        configuration.tables = %w[fortune teller]
        configuration.sql_replacement = 'my_\k<table>_view'
        configuration.sql_variables = { my_var: 1 }
        configuration.error { |error| raise 'Custom Error' }
      end
      mysql_client = ActiveRecord::MysqlRowLevelSecurity::ActiveRecordExceptionFake.new
      original_sql = 'SELECT * FROM fortune, teller'
      sql = ''
      sql.define_singleton_method(:original_sql) { original_sql }
      exception = assert_raises RuntimeError do
        mysql_client.execute(sql)
      end
      assert_equal 'Custom Error', exception.message
    end

    it 'sets init command for connection' do
      ActiveRecord::MysqlRowLevelSecurity.configure do |configuration|
        configuration.tables = %w[fortune teller]
        configuration.sql_replacement = 'my_\k<table>_view'
        configuration.sql_variables = { my_var: 1 }
      end
      assert_nil mysql_client.connection.query_options[:init_command]
      original_sql = 'SELECT * FROM fortune, teller'
      modified_sql, _ = mysql_client.execute(original_sql)
      assert_equal '/* SET @my_var := 1 */ SELECT * FROM my_fortune_view, my_teller_view', modified_sql
      assert_equal 'SET @my_var := 1', mysql_client.connection.query_options[:init_command]
    end
  end

  describe '#to_sql' do
    it 'returns a configuration with a view' do
      ActiveRecord::MysqlRowLevelSecurity.configure do |configuration|
        configuration.tables = %w[fortune teller]
        configuration.sql_replacement = 'my_\k<table>_view'
        configuration.sql_variables = { my_var: 1 }
      end
      original_sql = 'SELECT * FROM fortune, teller'
      modified_sql, _ = mysql_client.to_sql(original_sql)
      assert_equal '/* SET @my_var := 1 */ SELECT * FROM my_fortune_view, my_teller_view', modified_sql
    end
  end
end
