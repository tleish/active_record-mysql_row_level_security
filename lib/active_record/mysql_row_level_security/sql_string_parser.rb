require 'active_record-mysql_row_level_security'

module ActiveRecord
  module MysqlRowLevelSecurity
    class SqlStringParser
      attr_reader :tables, :buffer, :output, :previous

      NON_WORD = /\W/
      QUOTE = ['"', "'"]
      STRING_ESCAPE = '\\'

      TYPE_QUOTE = :quote
      TYPE_NUMBER = :number
      TYPE_NON_WORD = :non_word
      TYPE_WORD = :word

      def initialize(tables: {})
        @tables = tables
        @buffer = []
        @output = ''
        @previous = ''
      end

      def parse(text)
        chars = text.chars
        chars.each_with_index do |char, index|
          case char
          when *QUOTE
            @previous_type = TYPE_QUOTE
            if buffer.first == char # end_quote?
              escaped = @escape
              buffer_add(char, true)
              flush_quote unless escaped || chars[index+1] == char
            else # start of quote
              flush unless quote?(buffer.first)
              buffer_add(char, true)
            end
          when NON_WORD
            flush unless @previous_type == NON_WORD
            @previous_type = NON_WORD
            buffer_add(char)
          else
            flush unless @previous_type == TYPE_WORD
            @previous_type = TYPE_WORD
            buffer_add(char)
          end
        end

        flush
        flush_quote
        output
      end

      private

      def buffer_add(char, quote=false)
        record_escape(char, quote)
        @previous = char
        @buffer << char
      end

      def record_escape(char, quote=false)
        if @escape
          @escape = false
        elsif char == STRING_ESCAPE
          @escape = true
        elsif quote
          @escape = (char == buffer.first)
        else
          @escape = false
        end
      end

      def flush_quote
        return unless buffer.any?
        @output << buffer.join
        reset_buffer
      end

      def flush
        buffer_first = buffer.first
        return unless buffer_first && !quote?(buffer_first)
        string = buffer.join
        @output << (tables[string.downcase] || string)
        reset_buffer
      end

      def quote?(char)
        QUOTE.include?(char)
      end

      def reset_buffer
        @escape = false
        @buffer = []
      end
    end
  end
end
