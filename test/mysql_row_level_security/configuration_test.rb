require 'test_helper'
require 'mysql_row_level_security'
require 'ostruct'

class MysqlRowLevelSecurity::RowUserFake
  attr_accessor :current_org_id, :current_master_org_id
end

describe MysqlRowLevelSecurity::Configuration do
  describe '#init_command' do
    it 'returns empty with no sql variables defined' do
      configuration = MysqlRowLevelSecurity::Configuration.new
      assert_empty configuration.init_command
    end

    it 'can save sql variables' do
      configuration = MysqlRowLevelSecurity::Configuration.new
      configuration.sql_variables = {foo: 1, bar: 2}
      assert_equal 'SET @foo := 1, @bar := 2', configuration.init_command
    end
  end

  describe '#sql_pattern' do
    it 'returns an empty SQL table regex pattern' do
      configuration = MysqlRowLevelSecurity::Configuration.new
      assert_equal //, configuration.sql_pattern
    end

    it 'returns a SQL table regex pattern' do
      configuration = MysqlRowLevelSecurity::Configuration.new
      configuration.tables = %w[posts comments]
      assert_equal /\b(?<table>posts|comments)\b/i, configuration.sql_pattern
    end
  end

  describe '#tables' do
    it 'returns an empty SQL table regex pattern' do
      configuration = MysqlRowLevelSecurity::Configuration.new
      assert_equal //, configuration.sql_pattern
    end

    it 'returns sql variables' do
      configuration = MysqlRowLevelSecurity::Configuration.new
      configuration.tables = %w[posts comments]
      assert_equal /\b(?<table>posts|comments)\b/i, configuration.sql_pattern
    end
  end

  describe '#tables_hash' do
    it 'returns an empty hash with no configuration' do
      configuration = MysqlRowLevelSecurity::Configuration.new
      assert_equal({}, configuration.tables_hash)
    end

    it 'returns an table hash if there are no tables to modify' do
      configuration = MysqlRowLevelSecurity::Configuration.new
      configuration.tables = %w[posts comments]
      assert_equal({}, configuration.tables_hash)
    end

    it 'returns a table hash with custom pattern' do
      configuration = MysqlRowLevelSecurity::Configuration.new
      configuration.tables = %w[posts comments]
      configuration.sql_replacement = 'user_\k<table>_view'
      assert_equal({'posts' => 'user_posts_view', 'comments' => 'user_comments_view'}, configuration.tables_hash)
    end
  end

  describe '#sql_replacement' do
    it 'has a default' do
      configuration = MysqlRowLevelSecurity::Configuration.new
      configuration.tables = %w[foo]
      assert_equal '\k<table>', configuration.sql_replacement
    end

    it 'replaces empty with default' do
      configuration = MysqlRowLevelSecurity::Configuration.new
      configuration.tables = %w[foo]
      configuration.sql_replacement = ''
      assert_equal '\k<table>', configuration.sql_replacement
    end


    it 'sets a sql_replacement' do
      configuration = MysqlRowLevelSecurity::Configuration.new
      configuration.tables = %w[foo]
      configuration.sql_replacement = 'user_\k<table>_view'
        assert_equal 'user_\k<table>_view', configuration.sql_replacement
    end
  end

  describe '#error' do
    it 'executes a callback' do
      configuration = MysqlRowLevelSecurity::Configuration.new
      configuration.error do |error|
        error
      end
      assert_equal 'MyError', configuration.error_callback.call('MyError')
    end

    it 'default callback does nothing' do
      configuration = MysqlRowLevelSecurity::Configuration.new
      exception = assert_raises RuntimeError do
        configuration.error_callback.call('MyError')
      end
      assert_equal 'MyError', exception.message
    end
  end
end
