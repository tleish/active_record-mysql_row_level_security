require 'test_helper'
require 'active_record/mysql_row_level_security/sql_string_anonymizer'

describe ActiveRecord::MysqlRowLevelSecurity::SqlStringParser do
  let(:parser) { ActiveRecord::MysqlRowLevelSecurity::SqlStringAnonymizer.new }

  describe 'anonymize double quote' do
    it 'standard' do
      sql = 'SELECT * FROM comments WHERE comments.posts_type = "posts" AND comments.field = "comments"'
      assert_equal 'SELECT * FROM comments WHERE comments.posts_type = ? AND comments.field = ?', parser.parse(sql)
    end

    it 'matches with backlash escaped strings' do
      sql = 'SELECT * FROM comments WHERE comments.posts_type = "posts na \" me" AND comments.field = "comments"'
      assert_equal 'SELECT * FROM comments WHERE comments.posts_type = ? AND comments.field = ?', parser.parse(sql)
    end

    it 'matches with double escaped strings' do
      sql = 'SELECT * FROM comments WHERE comments.posts_type = "posts na "" me" AND comments.field = "comments"'
      assert_equal 'SELECT * FROM comments WHERE comments.posts_type = ? AND comments.field = ?', parser.parse(sql)
    end

    it 'matches with backslash and double quote escaped strings' do
      sql = 'SELECT * FROM comments WHERE comments.posts_type = "posts na \" "" me" AND comments.field = "comments"'
      assert_equal 'SELECT * FROM comments WHERE comments.posts_type = ? AND comments.field = ?', parser.parse(sql)
    end

    it 'matches with more than one string' do
      sql = 'SELECT * FROM comments WHERE comments.posts_type = "posts" AND comments.field = "comments"'
      assert_equal 'SELECT * FROM comments WHERE comments.posts_type = ? AND comments.field = ?', parser.parse(sql)
    end

    it 'handles apostrophe' do
      sql = %(SELECT * FROM comments WHERE comments.posts_type = "posts' comments" AND comments.field = "comments")
      assert_equal %(SELECT * FROM comments WHERE comments.posts_type = ? AND comments.field = ?), parser.parse(sql)
    end

    it 'handles escaped quote at beginning of string' do
      sql = %(SELECT * FROM comments WHERE comments.posts_type = "\\"posts" AND comments.field = "comments")
      assert_equal %(SELECT * FROM comments WHERE comments.posts_type = ? AND comments.field = ?), parser.parse(sql)
    end

    it 'handles double quote escaped quote at beginning of string' do
      sql = %(SELECT * FROM comments WHERE comments.posts_type = """posts" AND comments.field = "comments")
      assert_equal %(SELECT * FROM comments WHERE comments.posts_type = ? AND comments.field = ?), parser.parse(sql)
    end

    it 'handles escaped quote at end of string' do
      sql = %(SELECT * FROM comments WHERE comments.posts_type = "posts\\"" AND comments.field = "comments")
      assert_equal %(SELECT * FROM comments WHERE comments.posts_type = ? AND comments.field = ?), parser.parse(sql)
    end

    it 'handles double quote escaped quote at end of string' do
      sql = %(SELECT * FROM comments WHERE comments.posts_type = "posts""" AND comments.field = "comments")
      assert_equal %(SELECT * FROM comments WHERE comments.posts_type = ? AND comments.field = ?), parser.parse(sql)
    end

    # see: https://dev.mysql.com/doc/refman/5.7/en/string-literals.html
    it 'full escaping of various types' do
      sql = %(SELECT * FROM comments WHERE comments.posts_type IN ("posts", "'posts'", "''posts''", "posts""comments", "\\"posts", "posts' comments"))
      assert_equal %(SELECT * FROM comments WHERE comments.posts_type IN (?, ?, ?, ?, ?, ?)), parser.parse(sql)
    end

    it 'handles sub-queries' do
      sql = %(SELECT * FROM post_view JOIN (SELECT * FROM comments WHERE comments.posts_type = 'posts''' AND comments.id = 1))
      assert_equal %(SELECT * FROM post_view JOIN (SELECT * FROM comments WHERE comments.posts_type = ? AND comments.id = ?)), parser.parse(sql)
    end
  end

  describe 'anonymize single quote' do
    it 'standard' do
      sql = "SELECT * FROM comments WHERE comments.posts_type = 'posts' AND comments.field = 'comments'"
      assert_equal "SELECT * FROM comments WHERE comments.posts_type = ? AND comments.field = ?", parser.parse(sql)
    end

    it 'matches with backlash escaped strings' do
      sql = %(SELECT * FROM comments WHERE comments.posts_type = 'posts na \\' me' AND comments.field = 'comments')
      assert_equal %(SELECT * FROM comments WHERE comments.posts_type = ? AND comments.field = ?), parser.parse(sql)
    end

    it 'matches with double escaped strings' do
      sql = %(SELECT * FROM comments WHERE comments.posts_type = 'posts na '' me' AND comments.field = 'comments')
      assert_equal %(SELECT * FROM comments WHERE comments.posts_type = ? AND comments.field = ?), parser.parse(sql)
    end

    it 'matches with backslash and double quote escaped strings' do
      sql = %(SELECT * FROM comments WHERE comments.posts_type = 'posts na \\' '' me' AND comments.field = 'comments')
      assert_equal  %(SELECT * FROM comments WHERE comments.posts_type = ? AND comments.field = ?), parser.parse(sql)
    end

    it 'matches with more than one string' do
      sql = "SELECT * FROM comments WHERE comments.posts_type = 'posts' AND comments.field = 'comments'"
      assert_equal "SELECT * FROM comments WHERE comments.posts_type = ? AND comments.field = ?", parser.parse(sql)
    end

    it 'handles single quote' do
      sql = %(SELECT * FROM comments WHERE comments.posts_type = 'posts" comments' AND comments.field = 'comments')
      assert_equal %(SELECT * FROM comments WHERE comments.posts_type = ? AND comments.field = ?), parser.parse(sql)
    end

    it 'handles escaped quote at beginning of string' do
      sql = %(SELECT * FROM comments WHERE comments.posts_type = '\\'posts' AND comments.field = 'comments')
      assert_equal %(SELECT * FROM comments WHERE comments.posts_type = ? AND comments.field = ?), parser.parse(sql)
    end

    it 'handles double quote escaped quote at beginning of string' do
      sql = %(SELECT * FROM comments WHERE comments.posts_type = '''posts' AND comments.field = 'comments')
      assert_equal %(SELECT * FROM comments WHERE comments.posts_type = ? AND comments.field = ?), parser.parse(sql)
    end

    it 'handles escaped quote at end of string' do
      sql = %(SELECT * FROM comments WHERE comments.posts_type = 'posts\\'' AND comments.field = 'comments')
      assert_equal %(SELECT * FROM comments WHERE comments.posts_type = ? AND comments.field = ?), parser.parse(sql)
    end

    it 'handles double quote escaped quote at end of string' do
      sql = %(SELECT * FROM comments WHERE comments.posts_type = 'posts''' AND comments.field = 'comments')
      assert_equal %(SELECT * FROM comments WHERE comments.posts_type = ? AND comments.field = ?), parser.parse(sql)
    end

    # see: https://dev.mysql.com/doc/refman/5.7/en/string-literals.html
    it 'full escaping of various types' do
      sql = %(SELECT * FROM comments WHERE posts_type IN ('hello', '"hello"', '""hello""', 'hel''lo', '\\'hello', 'posts" comments'))
      assert_equal %(SELECT * FROM comments WHERE posts_type IN (?, ?, ?, ?, ?, ?)), parser.parse(sql)
    end
  end

  describe 'anonymize integers' do
    it 'standard' do
      sql = "SELECT * FROM comments WHERE comments.posts_type = 5 AND comments.id = 123"
      assert_equal "SELECT * FROM comments WHERE comments.posts_type = ? AND comments.id = ?", parser.parse(sql)
    end

  end
end
