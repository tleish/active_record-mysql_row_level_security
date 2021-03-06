require 'test_helper'
require 'active_record/mysql_row_level_security/sql_string_parser'

describe ActiveRecord::MysqlRowLevelSecurity::SqlStringParser do
  let(:parser) { ActiveRecord::MysqlRowLevelSecurity::SqlStringParser.new(tables: {'posts' => 'post_view', 'comments' => 'my_comments_view'}) }

  describe 'table replacement' do
    it 'renames a specified table' do
      sql = 'SELECT * FROM comments'
      assert_equal 'SELECT * FROM my_comments_view', parser.parse(sql)
    end

    it 'renames a specified table in both SELECT, FROM and WHERE clause' do
      sql = 'SELECT posts.id, posts.name FROM posts WHERE posts.id = 123'
      assert_equal 'SELECT post_view.id, post_view.name FROM post_view WHERE post_view.id = 123', parser.parse(sql)
    end

    it 'renames multiple tables' do
      sql = 'SELECT * FROM comments, posts'
      assert_equal 'SELECT * FROM my_comments_view, post_view', parser.parse(sql)
    end

    it 'renames multiple tables' do
      sql = 'SELECT posts.id, posts.name, comments.content FROM posts JOIN comments ON comments.post_id = posts.id WHERE posts.id = 123'
      assert_equal 'SELECT post_view.id, post_view.name, my_comments_view.content FROM post_view JOIN my_comments_view ON my_comments_view.post_id = post_view.id WHERE post_view.id = 123', parser.parse(sql)
    end

    it 'renames multiple tables' do
      sql = 'SELECT posts.id, posts.name, comments.content FROM posts JOIN comments ON comments.post_id = posts.id WHERE posts.id = 123'
      assert_equal 'SELECT post_view.id, post_view.name, my_comments_view.content FROM post_view JOIN my_comments_view ON my_comments_view.post_id = post_view.id WHERE post_view.id = 123', parser.parse(sql)
    end
  end

  describe 'ignores table names in double quotes' do
    it 'standard' do
      sql = 'SELECT * FROM comments WHERE comments.posts_type = "posts" AND comments.field = "comments"'
      assert_equal 'SELECT * FROM my_comments_view WHERE my_comments_view.posts_type = "posts" AND my_comments_view.field = "comments"', parser.parse(sql)
    end

    it 'matches with backlash escaped strings' do
      sql = 'SELECT * FROM comments WHERE comments.posts_type = "posts na \" me" AND comments.field = "comments"'
      assert_equal 'SELECT * FROM my_comments_view WHERE my_comments_view.posts_type = "posts na \" me" AND my_comments_view.field = "comments"', parser.parse(sql)
    end

    it 'matches with double escaped strings' do
      sql = 'SELECT * FROM comments WHERE comments.posts_type = "posts na "" me" AND comments.field = "comments"'
      assert_equal 'SELECT * FROM my_comments_view WHERE my_comments_view.posts_type = "posts na "" me" AND my_comments_view.field = "comments"', parser.parse(sql)
    end

    it 'matches with backslash and double quote escaped strings' do
      sql = 'SELECT * FROM comments WHERE comments.posts_type = "posts na \" "" me" AND comments.field = "comments"'
      assert_equal 'SELECT * FROM my_comments_view WHERE my_comments_view.posts_type = "posts na \" "" me" AND my_comments_view.field = "comments"', parser.parse(sql)
    end

    it 'matches with more than one string' do
      sql = 'SELECT * FROM comments WHERE comments.posts_type = "posts" AND comments.field = "comments"'
      assert_equal 'SELECT * FROM my_comments_view WHERE my_comments_view.posts_type = "posts" AND my_comments_view.field = "comments"', parser.parse(sql)
    end

    it 'handles apostrophe' do
      sql = %(SELECT * FROM comments WHERE comments.posts_type = "posts' comments" AND comments.field = "comments")
      assert_equal %(SELECT * FROM my_comments_view WHERE my_comments_view.posts_type = "posts' comments" AND my_comments_view.field = "comments"), parser.parse(sql)
    end

    it 'handles escaped quote at beginning of string' do
      sql = %(SELECT * FROM comments WHERE comments.posts_type = "\\"posts" AND comments.field = "comments")
      assert_equal %(SELECT * FROM my_comments_view WHERE my_comments_view.posts_type = "\\"posts" AND my_comments_view.field = "comments"), parser.parse(sql)
    end

    it 'handles double quote escaped quote at beginning of string' do
      sql = %(SELECT * FROM comments WHERE comments.posts_type = """posts" AND comments.field = "comments")
      assert_equal %(SELECT * FROM my_comments_view WHERE my_comments_view.posts_type = """posts" AND my_comments_view.field = "comments"), parser.parse(sql)
    end

    it 'handles escaped quote at end of string' do
      sql = %(SELECT * FROM comments WHERE comments.posts_type = "posts\\"" AND comments.field = "comments")
      assert_equal %(SELECT * FROM my_comments_view WHERE my_comments_view.posts_type = "posts\\"" AND my_comments_view.field = "comments"), parser.parse(sql)
    end

    it 'handles double quote escaped quote at end of string' do
      sql = %(SELECT * FROM comments WHERE comments.posts_type = "posts""" AND comments.field = "comments")
      assert_equal %(SELECT * FROM my_comments_view WHERE my_comments_view.posts_type = "posts""" AND my_comments_view.field = "comments"), parser.parse(sql)
    end

    # see: https://dev.mysql.com/doc/refman/5.7/en/string-literals.html
    it 'full escaping of various types' do
      sql = %(SELECT * FROM comments WHERE comments.posts_type IN ("posts", "'posts'", "''posts''", "posts""comments", "\\"posts", "posts' comments"))
      assert_equal %(SELECT * FROM my_comments_view WHERE my_comments_view.posts_type IN ("posts", "'posts'", "''posts''", "posts""comments", "\\"posts", "posts' comments")), parser.parse(sql)
    end
  end

  describe 'ignores table names in single quotes' do
    it 'standard' do
      sql = "SELECT * FROM comments WHERE comments.posts_type = 'posts' AND comments.field = 'comments'"
      assert_equal "SELECT * FROM my_comments_view WHERE my_comments_view.posts_type = 'posts' AND my_comments_view.field = 'comments'", parser.parse(sql)
    end

    it 'matches with backlash escaped strings' do
      sql = %(SELECT * FROM comments WHERE comments.posts_type = 'posts na \\' me' AND comments.field = 'comments')
      assert_equal %(SELECT * FROM my_comments_view WHERE my_comments_view.posts_type = 'posts na \\' me' AND my_comments_view.field = 'comments'), parser.parse(sql)
    end

    it 'matches with double escaped strings' do
      sql = %(SELECT * FROM comments WHERE comments.posts_type = 'posts na '' me' AND comments.field = 'comments')
      assert_equal %(SELECT * FROM my_comments_view WHERE my_comments_view.posts_type = 'posts na '' me' AND my_comments_view.field = 'comments'), parser.parse(sql)
    end

    it 'matches with backslash and double quote escaped strings' do
      sql = %(SELECT * FROM comments WHERE comments.posts_type = 'posts na \\' '' me' AND comments.field = 'comments')
      assert_equal  %(SELECT * FROM my_comments_view WHERE my_comments_view.posts_type = 'posts na \\' '' me' AND my_comments_view.field = 'comments'), parser.parse(sql)
    end

    it 'matches with more than one string' do
      sql = "SELECT * FROM comments WHERE comments.posts_type = 'posts' AND comments.field = 'comments'"
      assert_equal "SELECT * FROM my_comments_view WHERE my_comments_view.posts_type = 'posts' AND my_comments_view.field = 'comments'", parser.parse(sql)
    end

    it 'handles single quote' do
      sql = %(SELECT * FROM comments WHERE comments.posts_type = 'posts" comments' AND comments.field = 'comments')
      assert_equal %(SELECT * FROM my_comments_view WHERE my_comments_view.posts_type = 'posts" comments' AND my_comments_view.field = 'comments'), parser.parse(sql)
    end

    it 'handles escaped quote at beginning of string' do
      sql = %(SELECT * FROM comments WHERE comments.posts_type = '\\'posts' AND comments.field = 'comments')
      assert_equal %(SELECT * FROM my_comments_view WHERE my_comments_view.posts_type = '\\'posts' AND my_comments_view.field = 'comments'), parser.parse(sql)
    end

    it 'handles double quote escaped quote at beginning of string' do
      sql = %(SELECT * FROM comments WHERE comments.posts_type = '''posts' AND comments.field = 'comments')
      assert_equal %(SELECT * FROM my_comments_view WHERE my_comments_view.posts_type = '''posts' AND my_comments_view.field = 'comments'), parser.parse(sql)
    end

    it 'handles escaped quote at end of string' do
      sql = %(SELECT * FROM comments WHERE comments.posts_type = 'posts\\'' AND comments.field = 'comments')
      assert_equal %(SELECT * FROM my_comments_view WHERE my_comments_view.posts_type = 'posts\\'' AND my_comments_view.field = 'comments'), parser.parse(sql)
    end

    it 'handles double quote escaped quote at end of string' do
      sql = %(SELECT * FROM comments WHERE comments.posts_type = 'posts''' AND comments.field = 'comments')
      assert_equal %(SELECT * FROM my_comments_view WHERE my_comments_view.posts_type = 'posts''' AND my_comments_view.field = 'comments'), parser.parse(sql)
    end

    # see: https://dev.mysql.com/doc/refman/5.7/en/string-literals.html
    it 'full escaping of various types' do
      sql = %(SELECT * FROM comments WHERE posts_type IN ('hello', '"hello"', '""hello""', 'hel''lo', '\\'hello', 'posts" comments'))
      assert_equal %(SELECT * FROM my_comments_view WHERE posts_type IN ('hello', '"hello"', '""hello""', 'hel''lo', '\\'hello', 'posts" comments')), parser.parse(sql)
    end
  end

  describe 'other' do
    it 'handles sub-queries' do
      sql = %(SELECT * FROM posts JOIN (SELECT * FROM comments WHERE comments.posts_type = 'posts''' AND comments.field = 'comments'))
      assert_equal %(SELECT * FROM post_view JOIN (SELECT * FROM my_comments_view WHERE my_comments_view.posts_type = 'posts''' AND my_comments_view.field = 'comments')), parser.parse(sql)
    end


    it 'handles carriage returnes' do
      sql = %(SELECT\n*\nFROM\ncomments\nWHERE comments.posts_type = 'posts''' AND comments.field = 'comments')
      assert_equal %(SELECT\n*\nFROM\nmy_comments_view\nWHERE my_comments_view.posts_type = 'posts''' AND my_comments_view.field = 'comments'), parser.parse(sql)
    end
  end
end
