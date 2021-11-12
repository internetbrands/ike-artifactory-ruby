require 'pry-byebug'
require 'simplecov'

# Wherever your SimpleCov.start block is (spec_helper.rb, test_helper.rb, or .simplecov)
SimpleCov.start do
  add_filter 'test'
  SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
  ])
end

require 'minitest/autorun'
require "minitest/reporters"
Minitest::Reporters.use! Minitest::Reporters::HtmlReporter.new

require 'fixtures/repo_data'
require 'ike_artifactory'


class FakeResponse
  def initialize(code)
    @code = code
  end

  def code
    code
  end

  def to_s
    "fake response"
  end
end
