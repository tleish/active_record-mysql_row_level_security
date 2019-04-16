require 'test_helper'
require 'mysql_row_guard/sql_string_parser'
require 'parslet/convenience'

class FooParser < Parslet::Parser
  rule(:foo) { str('foo') }
  root(:foo)
end

describe MysqlRowGuard::SqlStringParser do
  let(:parser) { MysqlRowGuard::SqlStringParser.new }

  describe 'double quotes' do
    it 'standard' do
      input = 'SELECT * FROM subscribers WHERE name = "name"'
      parser = MysqlRowGuard::SqlStringParser.new
      tree = parser.parse_with_debug(input)
      assert_equal [{:command=>'SELECT * FROM subscribers WHERE name = '}, {:string=>'"name"'}], tree
    end

    it 'matches with backlash escaped strings' do
      input = 'SELECT * FROM subscribers WHERE name = "na \" me"'
      parser = MysqlRowGuard::SqlStringParser.new
      tree = parser.parse_with_debug(input)
      assert_equal [{:command=>'SELECT * FROM subscribers WHERE name = '}, {:string=>'"na \" me"'}], tree
    end

    it 'matches with double escaped strings' do
      input = 'SELECT * FROM subscribers WHERE name = "na "" me"'
      parser = MysqlRowGuard::SqlStringParser.new
      tree = parser.parse_with_debug(input)
      assert_equal [{:command=>'SELECT * FROM subscribers WHERE name = '}, {:string=>'"na "" me"'}], tree
    end

    it 'matches with backslash and double escaped strings' do
      input = 'SELECT * FROM subscribers WHERE name = "na \" "" me"'
      parser = MysqlRowGuard::SqlStringParser.new
      tree = parser.parse_with_debug(input)
      assert_equal [{:command=>'SELECT * FROM subscribers WHERE name = '}, {:string=>'"na \" "" me"'}], tree
    end

    it 'matches with more than one string' do
      input = 'SELECT * FROM subscribers WHERE id = 2 name = "name" and age = "young"'
      parser = MysqlRowGuard::SqlStringParser.new
      tree = parser.parse_with_debug(input)
      assert_equal [{:command=>'SELECT * FROM subscribers WHERE id = 2 name = '}, {:string=>'"name"'}, {:command=>" and age = "}, {:string=>'"young"'}], tree
    end

    it 'handles single quote inside' do
      input = 'SELECT * FROM subscribers WHERE id = 2 name = "name\'s"'
      parser = MysqlRowGuard::SqlStringParser.new
      tree = parser.parse_with_debug(input)
      assert_equal [{:command=>'SELECT * FROM subscribers WHERE id = 2 name = '}, {:string=>'"name\'s"'}], tree
    end

    # see: https://dev.mysql.com/doc/refman/5.7/en/string-literals.html
    it 'full escaping' do
      input = %(SELECT "hello", "'hello'", "''hello''", "hel""lo", "\\"hello")
      parser = MysqlRowGuard::SqlStringParser.new
      tree = parser.parse_with_debug(input)
      assert_equal [{:command=>"SELECT "}, {:string=>"\"hello\""}, {:command=>", "}, {:string=>"\"'hello'\""}, {:command=>", "}, {:string=>"\"''hello''\""}, {:command=>", "}, {:string=>"\"hel\"\"lo\""}, {:command=>", "}, {:string=>"\"\\\"hello\""}], tree
    end
  end

  describe 'single quotes' do
    it 'standard' do
      input = "SELECT * FROM subscribers WHERE name = 'name'"
      parser = MysqlRowGuard::SqlStringParser.new
      tree = parser.parse_with_debug(input)
      assert_equal [{:command=>'SELECT * FROM subscribers WHERE name = '}, {:string=>"'name'"}], tree
    end

    it 'matches with backlash escaped strings' do
      input = "SELECT * FROM subscribers WHERE name = 'na \\' me'"
      parser = MysqlRowGuard::SqlStringParser.new
      tree = parser.parse_with_debug(input)
      assert_equal [{:command=>'SELECT * FROM subscribers WHERE name = '}, {:string=>"'na \\' me'"}], tree
    end

    it 'matches with double escaped strings' do
      input = "SELECT * FROM subscribers WHERE name = 'na '' me'"
      parser = MysqlRowGuard::SqlStringParser.new
      tree = parser.parse_with_debug(input)
      assert_equal [{:command=>'SELECT * FROM subscribers WHERE name = '}, {:string=>"'na '' me'"}], tree
    end

    it 'matches with backslash and double escaped strings' do
      input = "SELECT * FROM subscribers WHERE name = 'na \\' '' me'"
      parser = MysqlRowGuard::SqlStringParser.new
      tree = parser.parse_with_debug(input)
      assert_equal [{:command=>'SELECT * FROM subscribers WHERE name = '}, {:string=>"'na \\' '' me'"}], tree
    end

    it 'matches with more than one string' do
      input = "SELECT * FROM subscribers WHERE id = 2 name = 'name' and age = 'young'"
      parser = MysqlRowGuard::SqlStringParser.new
      tree = parser.parse_with_debug(input)
      assert_equal [{:command=>'SELECT * FROM subscribers WHERE id = 2 name = '}, {:string=>"'name'"}, {:command=>" and age = "}, {:string=>"'young'"}], tree
    end

    it 'handles double quote inside' do
      input = "SELECT * FROM subscribers WHERE id = 2 name = 'name\"s'"
      parser = MysqlRowGuard::SqlStringParser.new
      tree = parser.parse_with_debug(input)
      assert_equal [{:command=>'SELECT * FROM subscribers WHERE id = 2 name = '}, {:string=>"'name\"s'"}], tree
    end

    # see: https://dev.mysql.com/doc/refman/5.7/en/string-literals.html
    it 'full escaping' do
      input = %(SELECT 'hello', '"hello"', '""hello""', 'hel''lo', '\\'hello')
      parser = MysqlRowGuard::SqlStringParser.new
      tree = parser.parse_with_debug(input)
      assert_equal [{:command=>"SELECT "}, {:string=>"'hello'"}, {:command=>", "}, {:string=>"'\"hello\"'"}, {:command=>", "}, {:string=>"'\"\"hello\"\"'"}, {:command=>", "}, {:string=>"'hel''lo'"}, {:command=>", "}, {:string=>"'\\'hello'"}], tree
    end
  end

  describe 'other' do
    it 'considers backticks as commands' do
      input = 'SELECT * FROM `subscribers`'
      parser = MysqlRowGuard::SqlStringParser.new
      tree = parser.parse_with_debug(input)
      assert_equal [{:command=>'SELECT * FROM `subscribers`'}], tree
    end

    it 'handles multi-line' do
      input = "SELECT * FROM subscribers \n WHERE name = 'test'"
      parser = MysqlRowGuard::SqlStringParser.new
      tree = parser.parse_with_debug(input)
      assert_equal [{:command=>"SELECT * FROM subscribers \n WHERE name = "}, {:string=>"'test'"}], tree
    end

    it 'handles disappearing backslash' do
      input = "SELECT 'disappearing\\ backslash'"
      parser = MysqlRowGuard::SqlStringParser.new
      tree = parser.parse_with_debug(input)
      assert_equal [{:command=>"SELECT "}, {:string=>"'disappearing\\ backslash'"}], tree
    end
  end
end
