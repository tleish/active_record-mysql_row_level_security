require "test_helper"
require 'active_record-mysql_row_level_security'

class ::ActiveRecord::MysqlRowLevelSecurity::UserFake
  attr_accessor :current_org_id, :current_master_org_id
end

describe ActiveRecord::MysqlRowLevelSecurity do
  let(:mysql_client) { PlanSource::MysqlSafeView::MysqlClientFake.new }
  let(:user) { PlanSource::MysqlSafeView::UserFake.new }

  it 'stores configuration settings' do
    refute_nil ::ActiveRecord::MysqlRowLevelSecurity::VERSION
  end

  it 'stores configuration settings' do
    ActiveRecord::MysqlRowLevelSecurity.configure do |configuration|
      configuration.sql_variables = {foo: 0, bar: 'test'}
    end
    configuration = ActiveRecord::MysqlRowLevelSecurity.configuration
    assert_equal configuration.init_command, 'SET @foo := 0, @bar := "test"'
  end

  it 'plugin is enabled' do
    assert ActiveRecord::MysqlRowLevelSecurity.enabled?
  end

  it 'plugin can be disabled' do
    assert ActiveRecord::MysqlRowLevelSecurity.enabled?
    ActiveRecord::MysqlRowLevelSecurity.disable do
      assert !ActiveRecord::MysqlRowLevelSecurity.enabled?
    end
    assert ActiveRecord::MysqlRowLevelSecurity.enabled?
  end
end
