require 'mysql_row_guard'
require 'parslet'

module MysqlRowGuard
  class SqlStringParser < Parslet::Parser
    rule(:double_string) {
      str('"') >> (
        str('\\') >> any | str('""') >> any | str('"').absent? >> any
      ).repeat >> str('"')
    }

    rule(:single_string) {
      str("'") >> (
        str('\\') >> any | str("''") >> any | str("'").absent? >> any
      ).repeat >> str("'")
    }

    # rule(:table) { string.absent? >> (str('posts') | str('comments')).as(:table) }
    rule(:word) { match('[a-zA-Z_]').repeat }
    # rule(:table) { ((word.absent? >> any) >> (str('posts') | str('comments')).as(:table) >> word.absent? >> any) }
    # rule(:table) { ((word.absent? >> any).repeat >> (str('posts') | str('comments')).as(:table)) >> (word.absent? >> any) }
    rule(:table) { ((word.absent? >> any).repeat >> (str('posts') | str('comments'))).as(:table) }

    rule(:string) { (double_string | single_string).as(:string) }

    rule(:commands) { (string.absent? >> any).repeat(1) }

    rule(:commands_with_strings) { (commands.as(:command) | string).repeat }

    root :commands_with_strings
  end

  class SqlStringTransformer < Parslet::Transform
    def self.for
      self.new do
        rule(command: simple(:command)) do
          yield(command)
        end
      end
    end
    rule(string: simple(:string)) { string }
  end
end
