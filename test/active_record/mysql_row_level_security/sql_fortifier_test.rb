require 'test_helper'
require 'active_record-mysql_row_level_security'

class ActiveRecord::MysqlRowLevelSecurity::RowUserFake
  attr_accessor :current_org_id, :current_master_org_id
end

describe ActiveRecord::MysqlRowLevelSecurity::SqlFortifier do
  it 'returns sql without a view' do
    ActiveRecord::MysqlRowLevelSecurity.configure do |config|
      config.tables = %w[comments]
      config.sql_replacement = '\k<table>'
    end
    sql_fortifier = ActiveRecord::MysqlRowLevelSecurity::SqlFortifier.for(sql: 'comments', configuration: ActiveRecord::MysqlRowLevelSecurity.configuration)
    assert_equal 'comments', sql_fortifier.to_s
  end

  describe 'fingerprinting' do
    it 'reports true' do
      ActiveRecord::MysqlRowLevelSecurity.configure do |config|
        config.tables = %w[comments]
        config.sql_replacement = '\k<table>'
      end
      sql = ActiveRecord::MysqlRowLevelSecurity::SqlFortifier.for(sql: 'comments', configuration: ActiveRecord::MysqlRowLevelSecurity.configuration)
      assert ActiveRecord::MysqlRowLevelSecurity::SqlFingerPrinter.stamped?(sql)
    end

    # Note this is important since ActiveRecord will fail if it's not a String class
    it 'is still a string class' do
      ActiveRecord::MysqlRowLevelSecurity.configure do |config|
        config.tables = %w[comments]
        config.sql_replacement = '\k<table>'
        config.sql_variables = { my_var: 1 }
      end
      sql = ActiveRecord::MysqlRowLevelSecurity::SqlFortifier.for(sql: 'comments', configuration: ActiveRecord::MysqlRowLevelSecurity.configuration)
      assert String, sql.class
    end

    it 'reports false' do
      refute ActiveRecord::MysqlRowLevelSecurity::SqlFingerPrinter.stamped?('test')
    end

    it 'returns original_sql' do
      ActiveRecord::MysqlRowLevelSecurity.configure do |config|
        config.tables = %w[comments]
        config.sql_replacement = 'my_\k<table>_view'
        config.sql_variables = { my_var: 1 }
      end
      sql = ActiveRecord::MysqlRowLevelSecurity::SqlFortifier.for(sql: 'SELECT comments', configuration: ActiveRecord::MysqlRowLevelSecurity.configuration)
      original_sql = ActiveRecord::MysqlRowLevelSecurity::SqlFingerPrinter.original_sql(sql)
      assert_match /my_comments_view/, sql
      assert_equal 'SELECT comments', original_sql
    end

    it 'returns empty original_sql if no change' do
      ActiveRecord::MysqlRowLevelSecurity.configure do |config|
        config.tables = %w[comments]
        config.sql_replacement = ''
        config.sql_variables = { my_var: 1 }
      end
      sql = ActiveRecord::MysqlRowLevelSecurity::SqlFortifier.for(sql: 'SELECT comments', configuration: ActiveRecord::MysqlRowLevelSecurity.configuration)
      assert_equal '', ActiveRecord::MysqlRowLevelSecurity::SqlFingerPrinter.original_sql(sql)
    end
  end


  describe 'filter sql types' do
    it 'does not modify queries beginning with the SHOW command' do
      user = ActiveRecord::MysqlRowLevelSecurity::RowUserFake.new
      user.current_master_org_id = 1
      ActiveRecord::MysqlRowLevelSecurity.configure do |config|
        config.tables = %w[comments]
        config.sql_replacement = 'my_\k<table>_view'
        config.sql_variables = { my_var: 1 }
      end
      sql_fortifier = ActiveRecord::MysqlRowLevelSecurity::SqlFortifier.for(sql: 'DELETE comments', configuration: ActiveRecord::MysqlRowLevelSecurity.configuration)
      assert_equal 'DELETE comments', sql_fortifier.to_s
    end

    it 'does not modify queries with USE INDEX' do
      user = ActiveRecord::MysqlRowLevelSecurity::RowUserFake.new
      user.current_master_org_id = 1
      ActiveRecord::MysqlRowLevelSecurity.configure do |config|
        config.tables = %w[comments]
        config.sql_replacement = 'my_\k<table>_view'
        config.sql_variables = { my_var: 1 }
      end
      sql_fortifier = ActiveRecord::MysqlRowLevelSecurity::SqlFortifier.for(sql: 'SELECT * FROM comments USE INDEX my_comments', configuration: ActiveRecord::MysqlRowLevelSecurity.configuration)
      assert_equal 'SELECT * FROM comments USE INDEX my_comments', sql_fortifier.to_s
    end

    it 'does not modify queries beginning with the SHOW command' do
      user = ActiveRecord::MysqlRowLevelSecurity::RowUserFake.new
      user.current_master_org_id = 1
      ActiveRecord::MysqlRowLevelSecurity.configure do |config|
        config.tables = %w[comments]
        config.sql_replacement = 'my_\k<table>_view'
        config.sql_variables = { my_var: 1 }
        config.query_types = ['DELETE']
      end
      sql_fortifier = ActiveRecord::MysqlRowLevelSecurity::SqlFortifier.for(sql: 'DELETE comments', configuration: ActiveRecord::MysqlRowLevelSecurity.configuration)
      assert_equal '/* SET @my_var := 1 */ DELETE my_comments_view', sql_fortifier.to_s
      ActiveRecord::MysqlRowLevelSecurity.configuration.query_types = ActiveRecord::MysqlRowLevelSecurity::Configuration::DEFAULT_QUERY_TYPES
    end
  end

  it 'returns sql with a view' do
    user = ActiveRecord::MysqlRowLevelSecurity::RowUserFake.new
    user.current_master_org_id = 1
    ActiveRecord::MysqlRowLevelSecurity.configure do |config|
      config.tables = %w[comments]
      config.sql_replacement = 'my_\k<table>_view'
      config.sql_variables = { my_var: 1 }
    end
    sql_fortifier = ActiveRecord::MysqlRowLevelSecurity::SqlFortifier.for(sql: 'SELECT comments', configuration: ActiveRecord::MysqlRowLevelSecurity.configuration)
    assert_equal '/* SET @my_var := 1 */ SELECT my_comments_view', sql_fortifier.to_s
  end

  it 'does not modify queries beginning with the SHOW command' do
    user = ActiveRecord::MysqlRowLevelSecurity::RowUserFake.new
    user.current_master_org_id = 1
    ActiveRecord::MysqlRowLevelSecurity.configure do |config|
      config.tables = %w[comments]
      config.sql_replacement = 'my_\k<table>_view'
      config.sql_variables = { my_var: 1 }
    end
    sql_fortifier = ActiveRecord::MysqlRowLevelSecurity::SqlFortifier.for(sql: 'SHOW comments', configuration: ActiveRecord::MysqlRowLevelSecurity.configuration)
    assert_equal 'SHOW comments', sql_fortifier.to_s
  end

  it 'does not modify matching string literals' do
    user = ActiveRecord::MysqlRowLevelSecurity::RowUserFake.new
    user.current_master_org_id = 1
    ActiveRecord::MysqlRowLevelSecurity.configure do |config|
      config.tables = %w[posts comments]
      config.sql_replacement = 'my_\k<table>_view'
      config.sql_variables = { my_var: 1 }
    end
    sql_fortifier = ActiveRecord::MysqlRowLevelSecurity::SqlFortifier.for(sql: 'SELECT * FROM posts WHERE type = "comments"', configuration: ActiveRecord::MysqlRowLevelSecurity.configuration)
    assert_equal '/* SET @my_var := 1 */ SELECT * FROM my_posts_view WHERE type = "comments"', sql_fortifier.to_s
  end

  it 'caches mysql' do
    user = ActiveRecord::MysqlRowLevelSecurity::RowUserFake.new
    user.current_master_org_id = 1
    ActiveRecord::MysqlRowLevelSecurity.configure do |config|
      config.tables = %w[comments]
      config.sql_replacement = 'my_\k<table>_view'
      config.sql_variables = { my_var: 1 }
    end
    original_sql = 'SELECT * FROM something_else'
    cached_sql = ActiveRecord::MysqlRowLevelSecurity::SqlFortifier.for(sql: original_sql, configuration: ActiveRecord::MysqlRowLevelSecurity.configuration)
    already_cached_sql = nil
    ActiveRecord::MysqlRowLevelSecurity::SqlFortifier.stub :new, OpenStruct.new(sql: 'INVALID') do
      already_cached_sql = ActiveRecord::MysqlRowLevelSecurity::SqlFortifier.for(sql: cached_sql, configuration: ActiveRecord::MysqlRowLevelSecurity.configuration)
    end
    assert_equal cached_sql, already_cached_sql
  end

  it 'parses 10,000 requests in less than a second' do
    require 'benchmark'

    user = ActiveRecord::MysqlRowLevelSecurity::RowUserFake.new
    user.current_master_org_id = 1
    ActiveRecord::MysqlRowLevelSecurity.configure do |config|
      config.tables = %w[comments]
      config.sql_replacement = 'my_\k<table>_view'
      config.sql_variables = { my_var: 1 }
    end

    n = 10_000

    start_time = Time.now
    n.times do
      sql = 'SELECT * FROM posts WHERE type = "comments"'
      sql_fortifier = ActiveRecord::MysqlRowLevelSecurity::SqlFortifier.for(sql: sql, configuration: ActiveRecord::MysqlRowLevelSecurity.configuration)
      sql_fortifier.to_s
    end
    seconds = Time.now - start_time
    assert seconds < 0.75, "10,000 calls MUST execute in less than 1 second, this took #{seconds} seconds"
  end


end
