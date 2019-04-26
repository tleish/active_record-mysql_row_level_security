$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "active_record-mysql_row_level_security"
require "minitest/autorun"
require 'minitest/reporters'

MiniTest::Reporters.use! [MiniTest::Reporters::DefaultReporter.new(color: true)]
