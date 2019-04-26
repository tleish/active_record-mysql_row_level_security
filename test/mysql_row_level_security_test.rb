require "test_helper"
require 'mysql_row_level_security'

class ::MysqlRowLevelSecurity::UserFake
  attr_accessor :current_org_id, :current_master_org_id
end

describe MysqlRowLevelSecurity do
  let(:mysql_client) { PlanSource::MysqlSafeView::MysqlClientFake.new }
  let(:user) { PlanSource::MysqlSafeView::UserFake.new }

  it 'stores configuration settings' do
    refute_nil ::MysqlRowLevelSecurity::VERSION
  end

  it 'stores configuration settings' do
    MysqlRowLevelSecurity.configure do |configuration|
      configuration.sql_variables = {foo: 0, bar: 'test'}
    end
    configuration = MysqlRowLevelSecurity.configuration
    assert_equal configuration.init_command, 'SET @foo := 0, @bar := "test"'
  end

  it 'plugin is enabled' do
    assert MysqlRowLevelSecurity.enabled?
  end

  it 'plugin can be disabled' do
    assert MysqlRowLevelSecurity.enabled?
    MysqlRowLevelSecurity.disable do
      assert !MysqlRowLevelSecurity.enabled?
    end
    assert MysqlRowLevelSecurity.enabled?
  end
end
