require 'test_helper'
require 'mysql_row_guard'
require 'ostruct'

class MysqlRowGuard::ActiveRecordFake
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
MysqlRowGuard::ActiveRecordFake.prepend MysqlRowGuard::ActiveRecord

describe MysqlRowGuard::ActiveRecord do
  let(:mysql_client) { MysqlRowGuard::ActiveRecordFake.new }

  describe '#execute' do
    it 'does not modify a query' do
      MysqlRowGuard.configure do |configuration|
        configuration.tables = %w[books comments]
      end
      MysqlRowGuard.configuration.sql_replacement = ''
      original_sql = 'SELECT * FROM books, comments'
      modified_sql, name = mysql_client.execute(original_sql, 'my name')
      assert_equal original_sql, modified_sql
      assert_equal 'my name', name
    end

    it 'returns a configuration with a view' do
      MysqlRowGuard.configure do |configuration|
        configuration.tables = %w[fortune teller]
        configuration.sql_replacement = 'my_%{table}_view'
        configuration.sql_variables = { my_var: 1 }
      end
      original_sql = 'SELECT * FROM fortune, teller'
      modified_sql, _ = mysql_client.execute(original_sql)
      assert_equal '/* SET @my_var := 1 */ SELECT * FROM my_fortune_view, my_teller_view', modified_sql
    end
  end

  describe '#to_sql' do
    it 'returns a configuration with a view' do
      MysqlRowGuard.configure do |configuration|
        configuration.tables = %w[fortune teller]
        configuration.sql_replacement = 'my_%{table}_view'
        configuration.sql_variables = { my_var: 1 }
      end
      original_sql = 'SELECT * FROM fortune, teller'
      modified_sql, _ = mysql_client.to_sql(original_sql)
      assert_equal '/* SET @my_var := 1 */ SELECT * FROM my_fortune_view, my_teller_view', modified_sql
    end
  end
end
