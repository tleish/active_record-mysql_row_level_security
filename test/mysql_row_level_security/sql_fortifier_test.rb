require 'test_helper'
require 'mysql_row_level_security'

class MysqlRowLevelSecurity::RowUserFake
  attr_accessor :current_org_id, :current_master_org_id
end

describe MysqlRowLevelSecurity::SqlFortifier do
  it 'returns sql without a view' do
    MysqlRowLevelSecurity.configure do |config|
      config.tables = %w[comments]
      config.sql_replacement = '\k<table>'
    end
    sql_fortifier = MysqlRowLevelSecurity::SqlFortifier.for(sql: 'comments', configuration: MysqlRowLevelSecurity.configuration)
    assert_equal 'comments', sql_fortifier.to_s
  end

  describe 'fingerprinting' do
    it 'reports true' do
      MysqlRowLevelSecurity.configure do |config|
        config.tables = %w[comments]
        config.sql_replacement = '\k<table>'
      end
      sql = MysqlRowLevelSecurity::SqlFortifier.for(sql: 'comments', configuration: MysqlRowLevelSecurity.configuration)
      assert MysqlRowLevelSecurity::SqlFingerPrinter.stamped?(sql)
    end

    # Note this is important since ActiveRecord will fail if it's not a String class
    it 'is still a string class' do
      MysqlRowLevelSecurity.configure do |config|
        config.tables = %w[comments]
        config.sql_replacement = '\k<table>'
        config.sql_variables = { my_var: 1 }
      end
      sql = MysqlRowLevelSecurity::SqlFortifier.for(sql: 'comments', configuration: MysqlRowLevelSecurity.configuration)
      assert String, sql.class
    end

    it 'reports false' do
      refute MysqlRowLevelSecurity::SqlFingerPrinter.stamped?('test')
    end

    it 'returns original_sql' do
      MysqlRowLevelSecurity.configure do |config|
        config.tables = %w[comments]
        config.sql_replacement = 'my_\k<table>_view'
        config.sql_variables = { my_var: 1 }
      end
      sql = MysqlRowLevelSecurity::SqlFortifier.for(sql: 'comments', configuration: MysqlRowLevelSecurity.configuration)
      original_sql = MysqlRowLevelSecurity::SqlFingerPrinter.original_sql(sql)
      assert_match /my_comments_view/, sql
      assert_equal 'comments', original_sql
    end

    it 'returns empty original_sql if no change' do
      MysqlRowLevelSecurity.configure do |config|
        config.tables = %w[comments]
        config.sql_replacement = ''
        config.sql_variables = { my_var: 1 }
      end
      sql = MysqlRowLevelSecurity::SqlFortifier.for(sql: 'comments', configuration: MysqlRowLevelSecurity.configuration)
      assert_equal '', MysqlRowLevelSecurity::SqlFingerPrinter.original_sql(sql)
    end
  end


  it 'returns sql with a view' do
    user = MysqlRowLevelSecurity::RowUserFake.new
    user.current_master_org_id = 1
    MysqlRowLevelSecurity.configure do |config|
      config.tables = %w[comments]
      config.sql_replacement = 'my_\k<table>_view'
      config.sql_variables = { my_var: 1 }
    end
    sql_fortifier = MysqlRowLevelSecurity::SqlFortifier.for(sql: 'comments', configuration: MysqlRowLevelSecurity.configuration)
    assert_equal '/* SET @my_var := 1 */ my_comments_view', sql_fortifier.to_s
  end

  it 'does not modify queries beginning with the SHOW command' do
    user = MysqlRowLevelSecurity::RowUserFake.new
    user.current_master_org_id = 1
    MysqlRowLevelSecurity.configure do |config|
      config.tables = %w[comments]
      config.sql_replacement = 'my_\k<table>_view'
      config.sql_variables = { my_var: 1 }
    end
    sql_fortifier = MysqlRowLevelSecurity::SqlFortifier.for(sql: 'SHOW comments', configuration: MysqlRowLevelSecurity.configuration)
    assert_equal 'SHOW comments', sql_fortifier.to_s
  end

  it 'does not modify matching string literals' do
    user = MysqlRowLevelSecurity::RowUserFake.new
    user.current_master_org_id = 1
    MysqlRowLevelSecurity.configure do |config|
      config.tables = %w[posts comments]
      config.sql_replacement = 'my_\k<table>_view'
      config.sql_variables = { my_var: 1 }
    end
    sql_fortifier = MysqlRowLevelSecurity::SqlFortifier.for(sql: 'SELECT * FROM posts WHERE type = "comments"', configuration: MysqlRowLevelSecurity.configuration)
    assert_equal '/* SET @my_var := 1 */ SELECT * FROM my_posts_view WHERE type = "comments"', sql_fortifier.to_s
  end

  it 'caches mysql' do
    user = MysqlRowLevelSecurity::RowUserFake.new
    user.current_master_org_id = 1
    MysqlRowLevelSecurity.configure do |config|
      config.tables = %w[comments]
      config.sql_replacement = 'my_\k<table>_view'
      config.sql_variables = { my_var: 1 }
    end
    original_sql = 'SELECT * FROM something_else'
    cached_sql = MysqlRowLevelSecurity::SqlFortifier.for(sql: original_sql, configuration: MysqlRowLevelSecurity.configuration)
    already_cached_sql = nil
    MysqlRowLevelSecurity::SqlFortifier.stub :new, OpenStruct.new(sql: 'INVALID') do
      already_cached_sql = MysqlRowLevelSecurity::SqlFortifier.for(sql: cached_sql, configuration: MysqlRowLevelSecurity.configuration)
    end
    assert_equal cached_sql, already_cached_sql
  end

  it 'parses 10,000 requests in less than a second' do
    require 'benchmark'

    user = MysqlRowLevelSecurity::RowUserFake.new
    user.current_master_org_id = 1
    MysqlRowLevelSecurity.configure do |config|
      config.tables = %w[comments]
      config.sql_replacement = 'my_\k<table>_view'
      config.sql_variables = { my_var: 1 }
    end

    n = 10_000

    start_time = Time.now
    n.times do
      sql = 'SELECT * FROM posts WHERE type = "comments"'
      sql_fortifier = MysqlRowLevelSecurity::SqlFortifier.for(sql: sql, configuration: MysqlRowLevelSecurity.configuration)
      sql_fortifier.to_s
    end
    seconds = Time.now - start_time
    assert seconds < 1, '10,000 calls MUST execute in less than 1 second'
  end


end
