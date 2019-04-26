require "mysql_row_level_security/version"
require 'mysql_row_level_security/configuration'
require 'mysql_row_level_security/sql_fortifier'
require 'mysql_row_level_security/active_record'

module MysqlRowLevelSecurity
  class Error < StandardError; end

  class << self
    attr_reader :enabled
    attr_writer :configuration
  end

  @configuration = Configuration.new
  def self.configuration
    MysqlRowLevelSecurity.disable do
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

  def self.disable(&block)
    @enabled = false
    begin
      results = block.call
    ensure # to always re-enable, regardless of the error
      @enabled = true
    end
    results
  end
end
