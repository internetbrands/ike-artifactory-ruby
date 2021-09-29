require 'test_helper'

class ClientFunctionalTest < Minitest::Test

  def setup
    super
    @artifactory = IKE::Artifactory::Client.new(
      :server => TEST_SERVER,
      :repo_key => TEST_REPO_KEY,
      :folder_path => TEST_FOLDER_PATH,
      :user => TEST_USER,
      :password => TEST_PASSWORD
    )
  end

  def test_setup_attributes
    artifactory = IKE::Artifactory::Client.new()
    artifactory.server = TEST_SERVER
    artifactory.repo_key = TEST_REPO_KEY
    artifactory.folder_path = TEST_FOLDER_PATH
  end

  def test_get_days_old_get_days_old_is_integer
    result = @artifactory.get_days_old '/ib'
    assert_instance_of Integer, result
  end

  def test_get_days_old_get_days_old_value
    result = @artifactory.get_days_old '/ib'
    assert result > 120
  end

  def test_get_object_info_returns_a_hash
    result = @artifactory.get_object_info '/ib/syncer'
    assert_instance_of Hash, result
  end

  def test_get_object_info_contains_created_by
    result = @artifactory.get_object_info '/ib/syncer'
    assert_includes(result.keys, 'createdBy')
  end

  def test_get_directories
    result = @artifactory.get_directories '/ib'

    assert_includes result, 'ship-it'
    assert_includes result, 'ruby-testing'
    assert_includes result, 'centos'
    assert_includes result, 'fedora'
    assert_instance_of Array, result
  end
  
end

