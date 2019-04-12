require 'test_helper'
require 'mysql_row_guard'
require 'ostruct'

class MysqlRowGuard::RowUserFake
  attr_accessor :current_org_id, :current_master_org_id
end

describe MysqlRowGuard::Configuration do
  describe '#init_command' do
    it 'returns empty with no sql variables defined' do
      configuration = MysqlRowGuard::Configuration.new
      assert_empty configuration.init_command
    end

    it 'can save sql variables' do
      configuration = MysqlRowGuard::Configuration.new
      configuration.sql_variables = {foo: 1, bar: 2}
      assert_equal 'SET @foo := 1, @bar := 2', configuration.init_command
    end
  end

  describe '#sql_pattern' do
    it 'returns an empty SQL table regex pattern' do
      configuration = MysqlRowGuard::Configuration.new
      assert_equal //, configuration.sql_pattern
    end

    it 'returns a SQL table regex pattern' do
      configuration = MysqlRowGuard::Configuration.new
      configuration.tables = %w[posts comments]
      assert_equal /\b(?<table>posts|comments)\b/i, configuration.sql_pattern
    end
  end

  describe '#tables' do
    it 'returns an empty SQL table regex pattern' do
      configuration = MysqlRowGuard::Configuration.new
      assert_equal //, configuration.sql_pattern
    end

    it 'returns sql variables' do
      configuration = MysqlRowGuard::Configuration.new
      configuration.tables = %w[posts comments]
      assert_equal /\b(?<table>posts|comments)\b/i, configuration.sql_pattern
    end
  end

  describe '#sql_replacement' do
    it 'returns a sql_replacement' do
      configuration = MysqlRowGuard::Configuration.new
      configuration.tables = %w[foo]
      assert_equal '\k<table>', configuration.sql_replacement
    end

    it 'sets a sql_replacement' do
      configuration = MysqlRowGuard::Configuration.new
      configuration.tables = %w[foo]
      configuration.sql_replacement = 'user_%{table}_view'
        assert_equal 'user_\k<table>_view', configuration.sql_replacement
    end
  end
end