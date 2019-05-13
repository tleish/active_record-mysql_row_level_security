require 'test_helper'
require 'active_record-mysql_row_level_security'
require 'ostruct'

class ActiveRecord::MysqlRowLevelSecurity::RowUserFake
  attr_accessor :current_org_id, :current_master_org_id
end

module ActiveRecord
  module ConfigurationResetCacheFake
    def reset_cache
      raise 'reset_cache should not have been called'
    end

    def self.reset_cache
      raise 'reset_cache should not have been called'
    end
  end
end

describe ActiveRecord::MysqlRowLevelSecurity::Configuration do
  describe '#init_command' do
    it 'returns empty with no sql variables defined' do
      configuration = ActiveRecord::MysqlRowLevelSecurity::Configuration.new
      assert_empty configuration.init_command
    end

    it 'can save sql variables' do
      configuration = ActiveRecord::MysqlRowLevelSecurity::Configuration.new
      configuration.sql_variables = {foo: 1, bar: 2}
      assert_equal 'SET @foo := 1, @bar := 2', configuration.init_command
    end
  end

  describe '#sql_variables' do
    it 'resets variables' do
      configuration = ActiveRecord::MysqlRowLevelSecurity::Configuration.new
      configuration.sql_variables = {test: 1}

      configuration.init_command
      refute configuration.instance_variable_get("@init_command").nil?
      configuration.sql_variables = {test: 2}
      assert configuration.instance_variable_get("@init_command").nil?
    end

    it 'does not reset variables' do
      configuration = ActiveRecord::MysqlRowLevelSecurity::Configuration.new
      configuration.sql_variables = {test: 1}

      configuration.init_command
      refute configuration.instance_variable_get("@init_command").nil?
      configuration.sql_variables = {test: 1}
      refute configuration.instance_variable_get("@init_command").nil?
    end
  end

  describe '#sql_pattern' do
    it 'returns an empty SQL table regex pattern' do
      configuration = ActiveRecord::MysqlRowLevelSecurity::Configuration.new
      assert_equal //, configuration.sql_pattern
    end

    it 'returns a SQL table regex pattern' do
      configuration = ActiveRecord::MysqlRowLevelSecurity::Configuration.new
      configuration.tables = %w[posts comments]
      assert_equal /\b(?<table>posts|comments)\b/i, configuration.sql_pattern
    end
  end

  describe '#tables' do
    it 'returns an empty SQL table regex pattern' do
      configuration = ActiveRecord::MysqlRowLevelSecurity::Configuration.new
      assert_equal //, configuration.sql_pattern
    end

    it 'returns sql variables' do
      configuration = ActiveRecord::MysqlRowLevelSecurity::Configuration.new
      configuration.tables = %w[posts comments]
      assert_equal /\b(?<table>posts|comments)\b/i, configuration.sql_pattern
    end

    it 'resets variables' do
      configuration = ActiveRecord::MysqlRowLevelSecurity::Configuration.new
      configuration.tables = %w[foo]
      configuration.sql_variables = {test: 1}

      configuration.init_command
      refute configuration.instance_variable_get("@init_command").nil?
      configuration.tables = %w[other]
      assert configuration.instance_variable_get("@init_command").nil?
    end

    it 'does not reset variables' do
      configuration = ActiveRecord::MysqlRowLevelSecurity::Configuration.new
      configuration.tables = %w[foo]
      configuration.sql_variables = {test: 1}

      configuration.init_command
      refute configuration.instance_variable_get("@init_command").nil?
      configuration.tables = %w[foo]
      refute configuration.instance_variable_get("@init_command").nil?
    end
  end

  describe '#tables_hash' do
    it 'returns an empty hash with no configuration' do
      configuration = ActiveRecord::MysqlRowLevelSecurity::Configuration.new
      assert_equal({}, configuration.tables_hash)
    end

    it 'returns an table hash if there are no tables to modify' do
      configuration = ActiveRecord::MysqlRowLevelSecurity::Configuration.new
      configuration.tables = %w[posts comments]
      assert_equal({}, configuration.tables_hash)
    end

    it 'returns a table hash with custom pattern' do
      configuration = ActiveRecord::MysqlRowLevelSecurity::Configuration.new
      configuration.tables = %w[posts comments]
      configuration.sql_replacement = 'user_\k<table>_view'
      assert_equal({'posts' => 'user_posts_view', 'comments' => 'user_comments_view'}, configuration.tables_hash)
    end


    it 'resets variables' do
      configuration = ActiveRecord::MysqlRowLevelSecurity::Configuration.new
      configuration.tables = %w[foo]
      configuration.sql_replacement = 'user_\k<table>_view'
      configuration.sql_variables = {test: 1}

      configuration.init_command
      refute configuration.instance_variable_get("@init_command").nil?
      configuration.sql_replacement = '\k<table>'
      assert configuration.instance_variable_get("@init_command").nil?
    end

    it 'does not reset variables' do
      configuration = ActiveRecord::MysqlRowLevelSecurity::Configuration.new
      configuration.tables = %w[foo]
      configuration.sql_replacement = 'user_\k<table>_view'
      configuration.sql_variables = {test: 1}

      configuration.init_command
      refute configuration.instance_variable_get("@init_command").nil?
      configuration.sql_replacement = 'user_\k<table>_view'
      refute configuration.instance_variable_get("@init_command").nil?
    end
  end

  describe '#sql_replacement' do
    it 'has a default' do
      configuration = ActiveRecord::MysqlRowLevelSecurity::Configuration.new
      configuration.tables = %w[foo]
      assert_equal '\k<table>', configuration.sql_replacement
    end

    it 'replaces empty with default' do
      configuration = ActiveRecord::MysqlRowLevelSecurity::Configuration.new
      configuration.tables = %w[foo]
      configuration.sql_replacement = ''
      assert_equal '\k<table>', configuration.sql_replacement
    end

    it 'sets a sql_replacement' do
      configuration = ActiveRecord::MysqlRowLevelSecurity::Configuration.new
      configuration.tables = %w[foo]
      configuration.sql_replacement = 'user_\k<table>_view'
        assert_equal 'user_\k<table>_view', configuration.sql_replacement
    end

    it 'resets variables' do
      configuration = ActiveRecord::MysqlRowLevelSecurity::Configuration.new
      configuration.tables = %w[foo]
      configuration.sql_replacement = 'user_\k<table>_view'
      configuration.sql_variables = {test: 1}

      configuration.init_command
      refute configuration.instance_variable_get("@init_command").nil?
      configuration.sql_replacement = '\k<table>'
      assert configuration.instance_variable_get("@init_command").nil?
    end

    it 'does not reset variables' do
      configuration = ActiveRecord::MysqlRowLevelSecurity::Configuration.new
      configuration.tables = %w[foo]
      configuration.sql_replacement = 'user_\k<table>_view'
      configuration.sql_variables = {test: 1}

      configuration.init_command
      refute configuration.instance_variable_get("@init_command").nil?
      configuration.sql_replacement = 'user_\k<table>_view'
      refute configuration.instance_variable_get("@init_command").nil?
    end
  end

  describe '#error' do
    it 'executes a callback' do
      configuration = ActiveRecord::MysqlRowLevelSecurity::Configuration.new
      configuration.error do |error|
        error
      end
      assert_equal 'MyError', configuration.error_callback.call('MyError')
    end

    it 'default callback does nothing' do
      configuration = ActiveRecord::MysqlRowLevelSecurity::Configuration.new
      exception = configuration.error_callback.call('MyError')
      assert_nil exception
    end
  end

  describe '#query_types' do
    it 'defaults to SELECT' do
      configuration = ActiveRecord::MysqlRowLevelSecurity::Configuration.new
      assert configuration.query_types_match?('SELECT *')
    end

    it 'can update' do
      configuration = ActiveRecord::MysqlRowLevelSecurity::Configuration.new
      configuration.query_types = ['UPDATE']
      refute configuration.query_types_match?('SELECT FROM UPDATE')
      assert configuration.query_types_match?('UPDATE *')
      configuration.query_types = ActiveRecord::MysqlRowLevelSecurity::Configuration::DEFAULT_QUERY_TYPES # reset back
    end
  end
end
