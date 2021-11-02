require "minitest/autorun"
require 'ike_artifactory'
require 'fixtures/repo_data'
require 'pry-byebug'

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
