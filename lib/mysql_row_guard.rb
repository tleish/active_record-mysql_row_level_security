require "mysql_row_guard/version"
require 'mysql_row_guard/configuration'
require 'mysql_row_guard/sql_fortifier'
require 'mysql_row_guard/active_record'

module MysqlRowGuard
  class Error < StandardError; end

  class << self
    attr_reader :enabled
    attr_writer :configuration
  end

  @configuration = Configuration.new
  def self.configuration
    MysqlRowGuard.disable do
      @configuration_callback.call(@configuration) if @configuration_callback.is_a? Proc
      @configuration
    end
  end

  def self.configure(&block)
    # reset_configuration
    @configuration_callback = block
  end

  def self.reset_configuration
    @configuration = Configuration.new
  end

  @enabled = true
  def self.enabled?
    @enabled
  end

  def self.disable
    @enabled = false
    begin
      results = yield
    ensure # to always re-enable, regardless of the error
      @enabled = true
    end
    results
  end
end
