require "test_helper"
require 'mysql_row_guard'

class ::MysqlRowGuard::UserFake
  attr_accessor :current_org_id, :current_master_org_id
end

describe MysqlRowGuard do
  let(:mysql_client) { PlanSource::MysqlSafeView::MysqlClientFake.new }
  let(:user) { PlanSource::MysqlSafeView::UserFake.new }

  it 'stores configuration settings' do
    refute_nil ::MysqlRowGuard::VERSION
  end

  it 'stores configuration settings' do
    MysqlRowGuard.configure do |configuration|
      configuration.sql_variables = {foo: 0, bar: 'test'}
    end
    configuration = MysqlRowGuard.configuration
    assert_equal configuration.init_command, 'SET @foo := 0, @bar := "test"'
  end

  it 'plugin is enabled' do
    assert MysqlRowGuard.enabled?
  end

  it 'plugin can be disabled' do
    assert MysqlRowGuard.enabled?
    MysqlRowGuard.disable do
      assert !MysqlRowGuard.enabled?
    end
    assert MysqlRowGuard.enabled?
  end
end
