require "active_record/mysql_row_level_security/version"
require 'active_record/mysql_row_level_security/configuration'
require 'active_record/mysql_row_level_security/active_record_fortifier'

module ActiveRecord
  module MysqlRowLevelSecurity
    class Error < StandardError; end

    class << self
      attr_reader :enabled
      attr_writer :configuration
    end

    @configuration = Configuration.new
    def self.configuration
      ActiveRecord::MysqlRowLevelSecurity.disable do
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
end
