require "mysql_row_guard/version"
require 'mysql_row_guard/configuration'
require 'mysql_row_guard/sql_fortifier'
require 'mysql_row_guard/active_record'

module MysqlRowGuard
  class Error < StandardError; end

  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration = Configuration.new
    @configuration_callback.call(@configuration) if @configuration_callback.is_a? Proc
    @configuration
  end

  def self.configure(&block)
    @configuration_callback = block
  end
end
