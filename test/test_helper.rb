$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "mysql_row_guard"
require "minitest/autorun"
require 'minitest/reporters'

MiniTest::Reporters.use! [MiniTest::Reporters::DefaultReporter.new(color: true)]