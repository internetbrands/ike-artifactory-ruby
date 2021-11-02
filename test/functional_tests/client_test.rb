require 'test_helper'

class ClientFunctionalTest < Minitest::Test

  def setup
    super
    @artifactory = IKE::Artifactory::Client.new(
      :server => TEST_SERVER,
      :repo_key => TEST_REPO_KEY,
      :user => TEST_USER,
      :password => TEST_PASSWORD
    )
  end

  def test_get_object_age_get_days_old_is_integer
    mock_response = Minitest::Mock.new
    mock_response.expect :code, 200
    mock_response.expect :to_str, '{ "lastModified": "2021-05-20T15:27:21.592-07:00" }'
    RestClient::Request.stub :execute,
                             nil,
                             [mock_response, 'fake-request', 'fake-result'] do
      result = @artifactory.get_object_age '/fake-folder'
      assert_instance_of Integer, result
    end
  end

  def test_get_object_age_get_days_old_value
    mock_response = Minitest::Mock.new
    mock_response.expect :code, 200
    mock_response.expect :to_str, '{ "lastModified": "2021-05-20T15:27:21.592-07:00" }'
    RestClient::Request.stub :execute,
                             nil,
                             [mock_response, 'fake-request', 'fake-result'] do
      result = @artifactory.get_object_age '/fake-folder'
      assert result > 120
    end
  end

  def test_get_object_info_returns_a_hash
    mock_response = Minitest::Mock.new
    mock_response.expect :code, 200
    mock_response.expect :to_str, '{ "lastModified": "2021-05-20T15:27:21.592-07:00" }'
    RestClient::Request.stub :execute,
                             nil,
                             [mock_response, 'fake-request', 'fake-result'] do
      result = @artifactory.get_object_info '/fake-folder'
      assert_instance_of Hash, result
    end
  end

  def test_get_object_info_contains_created_by
    mock_response = Minitest::Mock.new
    mock_response.expect :code, 200
    mock_response.expect :to_str, '{ "lastModified": "2021-05-20T15:27:21.592-07:00", "createdBy": "fake-dev"}'

    RestClient::Request.stub :execute,
                             nil,
                             [mock_response, 'fake-request', 'fake-result'] do
      result = @artifactory.get_object_info '/fake-folder'
      assert_includes(result.keys, 'createdBy')
    end
  end

  def test_get_directories
    mock_response = Minitest::Mock.new
    mock_response.expect :code, 200
    mock_response.expect :to_str, '{ "children": [{"uri": "/fake-folder-1", "folder": true}, {"uri": "/fake-folder-2", "folder": true}, {"uri": "/fake-folder-3", "folder": true}]}'

    RestClient::Request.stub :execute,
                             nil,
                             [mock_response, 'fake-request', 'fake-result'] do
      result = @artifactory.get_subdirectories '/fake-folder'
      assert_includes result, 'fake-folder-1'
      assert_includes result, 'fake-folder-2'
      assert_includes result, 'fake-folder-3'
    end
  end
end
