require 'test_helper'
require 'mysql_row_guard'

class MysqlRowGuard::RowUserFake
  attr_accessor :current_org_id, :current_master_org_id
end

describe MysqlRowGuard::SqlFortifier do
  it 'returns sql without a view' do
    MysqlRowGuard.configure do |config|
      config.tables = %w[comments]
      config.sql_replacement = '\k<table>'
    end
    sql_fortifier = MysqlRowGuard::SqlFortifier.for(sql: 'comments', configuration: MysqlRowGuard.configuration)
    assert_equal 'comments', sql_fortifier.to_s
  end

  describe 'fingerprinting' do
    it 'reports true' do
      MysqlRowGuard.configure do |config|
        config.tables = %w[comments]
        config.sql_replacement = '\k<table>'
      end
      sql = MysqlRowGuard::SqlFortifier.for(sql: 'comments', configuration: MysqlRowGuard.configuration)
      assert MysqlRowGuard::SqlFingerPrinter.stamped?(sql)
    end

    # Note this is important since ActiveRecord will fail if it's not a String class
    it 'is still a string class' do
      MysqlRowGuard.configure do |config|
        config.tables = %w[comments]
        config.sql_replacement = '\k<table>'
        config.sql_variables = { my_var: 1 }
      end
      sql = MysqlRowGuard::SqlFortifier.for(sql: 'comments', configuration: MysqlRowGuard.configuration)
      assert String, sql.class
    end

    it 'reports false' do
      refute MysqlRowGuard::SqlFingerPrinter.stamped?('test')
    end

    it 'returns original_sql' do
      MysqlRowGuard.configure do |config|
        config.tables = %w[comments]
        config.sql_replacement = 'my_\k<table>_view'
        config.sql_variables = { my_var: 1 }
      end
      sql = MysqlRowGuard::SqlFortifier.for(sql: 'comments', configuration: MysqlRowGuard.configuration)
      original_sql = MysqlRowGuard::SqlFingerPrinter.original_sql(sql)
      assert_match /my_comments_view/, sql
      assert_equal 'comments', original_sql
    end

    it 'returns empty original_sql if no change' do
      MysqlRowGuard.configure do |config|
        config.tables = %w[comments]
        config.sql_replacement = ''
        config.sql_variables = { my_var: 1 }
      end
      sql = MysqlRowGuard::SqlFortifier.for(sql: 'comments', configuration: MysqlRowGuard.configuration)
      assert_equal '', MysqlRowGuard::SqlFingerPrinter.original_sql(sql)
    end
  end


  it 'returns sql with a view' do
    user = MysqlRowGuard::RowUserFake.new
    user.current_master_org_id = 1
    MysqlRowGuard.configure do |config|
      config.tables = %w[comments]
      config.sql_replacement = 'my_\k<table>_view'
      config.sql_variables = { my_var: 1 }
    end
    sql_fortifier = MysqlRowGuard::SqlFortifier.for(sql: 'comments', configuration: MysqlRowGuard.configuration)
    assert_equal '/* SET @my_var := 1 */ my_comments_view', sql_fortifier.to_s
  end

  it 'does not modify queries beginning with the SHOW command' do
    user = MysqlRowGuard::RowUserFake.new
    user.current_master_org_id = 1
    MysqlRowGuard.configure do |config|
      config.tables = %w[comments]
      config.sql_replacement = 'my_\k<table>_view'
      config.sql_variables = { my_var: 1 }
    end
    sql_fortifier = MysqlRowGuard::SqlFortifier.for(sql: 'SHOW comments', configuration: MysqlRowGuard.configuration)
    assert_equal 'SHOW comments', sql_fortifier.to_s
  end

  it 'does not modify matching string literals' do
    user = MysqlRowGuard::RowUserFake.new
    user.current_master_org_id = 1
    MysqlRowGuard.configure do |config|
      config.tables = %w[posts comments]
      config.sql_replacement = 'my_\k<table>_view'
      config.sql_variables = { my_var: 1 }
    end
    sql_fortifier = MysqlRowGuard::SqlFortifier.for(sql: 'SELECT * FROM posts WHERE type = "comments"', configuration: MysqlRowGuard.configuration)
    assert_equal '/* SET @my_var := 1 */ SELECT * FROM my_posts_view WHERE type = "comments"', sql_fortifier.to_s
  end

  it 'caches mysql' do
    user = MysqlRowGuard::RowUserFake.new
    user.current_master_org_id = 1
    MysqlRowGuard.configure do |config|
      config.tables = %w[comments]
      config.sql_replacement = 'my_\k<table>_view'
      config.sql_variables = { my_var: 1 }
    end
    original_sql = 'SELECT * FROM something_else'
    cached_sql = MysqlRowGuard::SqlFortifier.for(sql: original_sql, configuration: MysqlRowGuard.configuration)
    already_cached_sql = nil
    MysqlRowGuard::SqlFortifier.stub :new, OpenStruct.new(sql: 'INVALID') do
      already_cached_sql = MysqlRowGuard::SqlFortifier.for(sql: cached_sql, configuration: MysqlRowGuard.configuration)
    end
    assert_equal cached_sql, already_cached_sql
  end

  it 'has a benchmark' do
    skip
    require 'benchmark'

    user = MysqlRowGuard::RowUserFake.new
    user.current_master_org_id = 1
    MysqlRowGuard.configure do |config|
      config.tables = %w[comments]
      config.sql_replacement = 'my_\k<table>_view'
      config.sql_variables = { my_var: 1 }
    end

    n = 10_000

    # require 'ruby-prof-flamegraph'
    # RubyProf.start

    Benchmark.bm(7) do |x|
      x.report("for:") do
        n.times do
          sql = 'SELECT * FROM posts WHERE type = "comments"'
          sql_fortifier = MysqlRowGuard::SqlFortifier.for(sql: sql, configuration: MysqlRowGuard.configuration)
          sql_fortifier.to_s
        end
      end
    end

    # result = RubyProf.stop
    # printer = RubyProf::FlameGraphPrinter.new(result)
    #
    # dir = File.dirname(__FILE__)
    # file = File.join(dir, "profile-#{Time.now.to_i}.data")
    # File.open(file, 'w') {|file| printer.print(file)}
    # flamegraph_processor = '~/Projects/src/github/FlameGraph/flamegraph.pl --countname=ms --width=1500'
    # cmd = "cat #{File.basename(file)} | #{flamegraph_processor} > #{File.basename(file, '.*')}_flamegraph.svg"
    # Dir.chdir(File.dirname(file)) { %x[#{cmd}] }
  end


end
