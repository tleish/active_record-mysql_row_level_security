require 'test_helper'
require 'mysql_row_guard/sql_string_parser_custom'

class FooParser < Parslet::Parser
  rule(:foo) { str('foo') }
  root(:foo)
end

describe MysqlRowGuard::SqlStringParserCustom do
  let(:parser) { MysqlRowGuard::SqlStringParserCustom.new }

  describe 'double quotes' do
    it 'seperates out double quotes' do
      input = 'first_name = "first_name" last_name = "last_name\'s"'
      tree = parser.parse(input)

      transformer = MysqlRowGuard::SqlStringTransformerCustom.new do |command|
        command.to_s.gsub(/\b(?<table>posts|comments)\b/i, 'user_\k<table>_view')
      end
      puts transformer.apply(tree).join
      assert_equal ["first_name", " ", "=", " ", "\"first_name\"", " ", "last_name", " ", "=", " ", "\"last_name's\""], tree
    end

    # it 'standard' do
    #   input = 'SELECT * FROM subscribers WHERE name = "name"'
    #   tree = parser.parse(input)
    #   assert_equal [{:command=>'SELECT * FROM subscribers WHERE name = '}, {:string=>'"name"'}], tree
    # end

    # it 'matches with backlash escaped strings' do
    #   input = 'SELECT * FROM subscribers WHERE name = "na \" me"'
    #   parser = MysqlRowGuard::SqlStringParser.new
    #   tree = parser.parse_with_debug(input)
    #   assert_equal [{:command=>'SELECT * FROM subscribers WHERE name = '}, {:string=>'"na \" me"'}], tree
    # end
    #
    # it 'matches with double escaped strings' do
    #   input = 'SELECT * FROM subscribers WHERE name = "na "" me"'
    #   parser = MysqlRowGuard::SqlStringParser.new
    #   tree = parser.parse_with_debug(input)
    #   assert_equal [{:command=>'SELECT * FROM subscribers WHERE name = '}, {:string=>'"na "" me"'}], tree
    # end
    #
    # it 'matches with backslash and double escaped strings' do
    #   input = 'SELECT * FROM subscribers WHERE name = "na \" "" me"'
    #   parser = MysqlRowGuard::SqlStringParser.new
    #   tree = parser.parse_with_debug(input)
    #   assert_equal [{:command=>'SELECT * FROM subscribers WHERE name = '}, {:string=>'"na \" "" me"'}], tree
    # end
    #
    # it 'matches with more than one string' do
    #   input = 'SELECT * FROM subscribers WHERE id = 2 name = "name" and age = "young"'
    #   parser = MysqlRowGuard::SqlStringParser.new
    #   tree = parser.parse_with_debug(input)
    #   assert_equal [{:command=>'SELECT * FROM subscribers WHERE id = 2 name = '}, {:string=>'"name"'}, {:command=>" and age = "}, {:string=>'"young"'}], tree
    # end
    #
    # it 'handles single quote inside' do
    #   input = 'SELECT * FROM subscribers WHERE id = 2 name = "name\'s"'
    #   parser = MysqlRowGuard::SqlStringParser.new
    #   tree = parser.parse_with_debug(input)
    #   assert_equal [{:command=>'SELECT * FROM subscribers WHERE id = 2 name = '}, {:string=>'"name\'s"'}], tree
    # end
    #
    # # see: https://dev.mysql.com/doc/refman/5.7/en/string-literals.html
    # it 'full escaping' do
    #   input = %(SELECT "hello", "'hello'", "''hello''", "hel""lo", "\\"hello")
    #   parser = MysqlRowGuard::SqlStringParser.new
    #   tree = parser.parse_with_debug(input)
    #   assert_equal [{:command=>"SELECT "}, {:string=>"\"hello\""}, {:command=>", "}, {:string=>"\"'hello'\""}, {:command=>", "}, {:string=>"\"''hello''\""}, {:command=>", "}, {:string=>"\"hel\"\"lo\""}, {:command=>", "}, {:string=>"\"\\\"hello\""}], tree
    # end
  end

  # describe 'single quotes' do
  #   it 'standard' do
  #     input = "SELECT * FROM subscribers WHERE name = 'name'"
  #     parser = MysqlRowGuard::SqlStringParser.new
  #     tree = parser.parse_with_debug(input)
  #     assert_equal [{:command=>'SELECT * FROM subscribers WHERE name = '}, {:string=>"'name'"}], tree
  #   end
  #
  #   it 'matches with backlash escaped strings' do
  #     input = "SELECT * FROM subscribers WHERE name = 'na \\' me'"
  #     parser = MysqlRowGuard::SqlStringParser.new
  #     tree = parser.parse_with_debug(input)
  #     assert_equal [{:command=>'SELECT * FROM subscribers WHERE name = '}, {:string=>"'na \\' me'"}], tree
  #   end
  #
  #   it 'matches with double escaped strings' do
  #     input = "SELECT * FROM subscribers WHERE name = 'na '' me'"
  #     parser = MysqlRowGuard::SqlStringParser.new
  #     tree = parser.parse_with_debug(input)
  #     assert_equal [{:command=>'SELECT * FROM subscribers WHERE name = '}, {:string=>"'na '' me'"}], tree
  #   end
  #
  #   it 'matches with backslash and double escaped strings' do
  #     input = "SELECT * FROM subscribers WHERE name = 'na \\' '' me'"
  #     parser = MysqlRowGuard::SqlStringParser.new
  #     tree = parser.parse_with_debug(input)
  #     assert_equal [{:command=>'SELECT * FROM subscribers WHERE name = '}, {:string=>"'na \\' '' me'"}], tree
  #   end
  #
  #   it 'matches with more than one string' do
  #     input = "SELECT * FROM subscribers WHERE id = 2 name = 'name' and age = 'young'"
  #     parser = MysqlRowGuard::SqlStringParser.new
  #     tree = parser.parse_with_debug(input)
  #     assert_equal [{:command=>'SELECT * FROM subscribers WHERE id = 2 name = '}, {:string=>"'name'"}, {:command=>" and age = "}, {:string=>"'young'"}], tree
  #   end
  #
  #   it 'handles double quote inside' do
  #     input = "SELECT * FROM subscribers WHERE id = 2 name = 'name\"s'"
  #     parser = MysqlRowGuard::SqlStringParser.new
  #     tree = parser.parse_with_debug(input)
  #     assert_equal [{:command=>'SELECT * FROM subscribers WHERE id = 2 name = '}, {:string=>"'name\"s'"}], tree
  #   end
  #
  #   # see: https://dev.mysql.com/doc/refman/5.7/en/string-literals.html
  #   it 'full escaping' do
  #     input = %(SELECT 'hello', '"hello"', '""hello""', 'hel''lo', '\\'hello')
  #     parser = MysqlRowGuard::SqlStringParser.new
  #     tree = parser.parse_with_debug(input)
  #     assert_equal [{:command=>"SELECT "}, {:string=>"'hello'"}, {:command=>", "}, {:string=>"'\"hello\"'"}, {:command=>", "}, {:string=>"'\"\"hello\"\"'"}, {:command=>", "}, {:string=>"'hel''lo'"}, {:command=>", "}, {:string=>"'\\'hello'"}], tree
  #   end
  # end

  describe 'other' do
    # it 'considers backticks as commands' do
    #   input = 'SELECT * FROM `subscribers`'
    #   parser = MysqlRowGuard::SqlStringParser.new
    #   tree = parser.parse_with_debug(input)
    #   assert_equal [{:command=>'SELECT * FROM `subscribers`'}], tree
    # end
    #
    # it 'handles multi-line' do
    #   input = "SELECT * FROM subscribers \n WHERE name = 'test'"
    #   parser = MysqlRowGuard::SqlStringParser.new
    #   tree = parser.parse_with_debug(input)
    #   assert_equal [{:command=>"SELECT * FROM subscribers \n WHERE name = "}, {:string=>"'test'"}], tree
    # end
    #
    # it 'handles disappearing backslash' do
    #   input = "SELECT 'disappearing\\ backslash'"
    #   parser = MysqlRowGuard::SqlStringParser.new
    #   tree = parser.parse_with_debug(input)
    #   assert_equal [{:command=>"SELECT "}, {:string=>"'disappearing\\ backslash'"}], tree
    # end

    it 'has a benchmark' do
      require 'benchmark'

      sql = "SELECT * FROM posts, post_comments WHERE type = 'comments'"
      parser = MysqlRowGuard::SqlStringParserCustom.new

      # transformer = MysqlRowGuard::SqlStringTransformerCustom.new do |command|
      #   command.gsub!(/\b(?<table>posts|comments)\b/i, 'user_\k<table>_view')
      # end
      #
      # transformer = MysqlRowGuard::SqlStringTransformerCustom.new do |command|
      #   command.sub('posts', 'user_posts_view')
      # end

      tables = {'posts' => 'user_posts_view', 'comments' => 'user_comments_view'}
      transformer = MysqlRowGuard::SqlStringTransformerCustom.new do |command|
        tables[command.downcase] || command
      end

      n = 10_000
      n = 1000

      # require 'ruby-prof-flamegraph'
      # RubyProf.start

      Benchmark.bm(7) do |x|
        x.report("parser:") do
          n.times do
            ast = parser.parse(sql)
            # transformer.apply(ast).join
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
end
