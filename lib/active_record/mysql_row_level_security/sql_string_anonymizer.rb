require 'active_record/mysql_row_level_security/sql_string_parser'

module ActiveRecord
  module MysqlRowLevelSecurity
    class SqlStringAnonymizer < SqlStringParser

      private

      def flush_quote
        return unless buffer.any?
        @output << '?'
        reset_buffer
      end

      def flush
        buffer_first = buffer.first
        return unless buffer_first && !quote?(buffer_first)
        string = buffer.join
        if string.to_i.to_s == string
          @output << '?'
        else
          @output << string
        end

        reset_buffer
      end
    end
  end
end
