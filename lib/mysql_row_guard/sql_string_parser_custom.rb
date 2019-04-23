require 'mysql_row_guard'
require 'parslet'

module MysqlRowGuard
  class SqlStringParserCustom
    attr_reader :buffer, :output

    BREAK_CHARS = [' ', '`', '.']

    DOUBLE_QUOTE = '"'
    SINGLE_QUOTE = "'"
    STRING_ESCAPE = '\\'

    def initialize
      @buffer = []
      @command_buffer = SqlStringCommandParserCustom.new
      @output = []
    end

    def parse(text)
      text.each_char do |char|
        case char
        when DOUBLE_QUOTE
          if buffer.first == DOUBLE_QUOTE # end_quote?
            @buffer << char
            flush_as_hash(key: :string) unless [STRING_ESCAPE, DOUBLE_QUOTE].include?(buffer[-2]) #escaped_quote?
          elsif buffer.first == SINGLE_QUOTE
            @buffer << char
          else
            flush_as_hash
            @buffer << char
          end
        when SINGLE_QUOTE
          if buffer.first == SINGLE_QUOTE # end_quote?
            @buffer << char
            flush_as_hash(key: :string) unless [STRING_ESCAPE, SINGLE_QUOTE].include?(buffer[-2]) #escaped_quote?
          elsif buffer.first == DOUBLE_QUOTE
            @buffer << char
          else
            flush_as_hash
            @buffer << char
          end
        # when *BREAK_CHARS
        #   flush if !BREAK_CHARS.include?(previous)
        #   @buffer << char
        else
          # flush if BREAK_CHARS.include?(previous)
          @buffer << char
        end
      end

      flush_as_hash
      output
    end

    private

    def flush_string
      if buffer.any?
        @output << buffer.join
        @buffer = []
      end
    end

    def flush_as_hash(key: :command)
      if buffer.any?
        @output << Hash[key, buffer.join]
        @buffer = []
      end
    end

    def flush
      if buffer.any?
        @output << buffer.join
        @buffer = []
      end
    end

    def previous
      buffer.last || ''
    end
  end


  class SqlStringCommandParserCustom
    attr_reader :buffer, :output

    WHITESPACE = /\s/
    NON_WHITESPACE = /\S/

    def initialize
      @buffer = []
      @output = []
    end

    def parse(text)
      text.each_char do |char|
        case char
        when WHITESPACE
          flush if previous.match(NON_WHITESPACE)
          @buffer << char
        else
          flush if previous.match(WHITESPACE)
          @buffer << char
        end
      end

      flush
      output
    end

    private

    def flush
      if buffer.any?
        @output << buffer.join
        @buffer = []
      end
    end

    def previous
      buffer.last || ''
    end
  end

  class SqlStringTransformerCustom
    def initialize(&block)
      @command = block
    end

    def apply(parsed)
      parsed.map do |item|
        if item[:command]
          @command.call(item[:command])
        else
          item[:string]
        end
      end
    end
  end

  # class QuoteParser
  #   QUOTE_ESCAPE = '\\'
  #
  #   def self.for(quote: '"', buffer: buffer)
  #     if buffer.first == quote # end_quote?
  #       if [QUOTE_ESCAPES, quote].include?(buffer[-2]) #escaped_quote?
  #         :nil
  #       else
  #         :string
  #       end
  #     else
  #       :command
  #     end
  #   end
  #
  #   def initalize(buffer: buffer, char: char)
  #
  #   end
  #
  #   def parse
  #     yield
  #     flush()
  #   end
  # end
  #
  # class QuoteParserString
  #   attr_reader :buffer
  #   def initialize(buffer: )
  #     @buffer = buffer
  #   end
  #
  #   def parse
  #     yield
  #     buffer.flush(:string)
  #   end
  # end
end
