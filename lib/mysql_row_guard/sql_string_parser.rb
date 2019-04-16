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
