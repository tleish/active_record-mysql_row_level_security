require 'mysql_row_guard'
require 'parslet'

module MysqlRowGuard
  class SqlStringParserCustom
    attr_reader :tables, :buffer, :output, :previous
    NON_WORD = /\W/
    QUOTE = ['"', "'"]
    STRING_ESCAPE = '\\'

    TYPE_QUOTE = 'QUOTE'
    TYPE_NON_WORD = 'NON_WORD'
    TYPE_WORD = 'WORD'

    def initialize(tables: {})
      @tables = tables
      @buffer = []
      @output = ''
      @previous = ''
    end

    def parse(text)
      text.each_char do |char|
        case char
        when *QUOTE
          @previous_type = TYPE_QUOTE
          if buffer.first == char # end_quote?
            escaped = @escape
            buffer_add(char)
            flush_quote unless escaped
          elsif buffer_quote?
            buffer_add(char)
          else # start of quote
            flush
            buffer_add(char)
          end
        when NON_WORD
          flush unless @previous_type == TYPE_NON_WORD
          @previous_type = TYPE_NON_WORD
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

    def buffer_add(char)
      if @escape
        @escape = false
      else
        @escape = ([STRING_ESCAPE, buffer.first].include?(char) && buffer_quote?)
      end
      @previous = char
      @buffer << char
    end

    def flush_quote
      return unless buffer.any?
      @output << buffer.join
      reset_buffer
    end

    def flush
      return unless buffer.any? && !buffer_quote?
      string = buffer.join
      @output << (tables[string.downcase] || string)
      reset_buffer
    end

    def buffer_quote?
      QUOTE.include?(buffer.first)
    end

    def first
      @first ||= buffer.first
    end

    def reset_buffer
      @escape = false
      @buffer = []
    end
  end
end
