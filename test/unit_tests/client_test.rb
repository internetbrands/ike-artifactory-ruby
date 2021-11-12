require 'test_helper'

TIME_LAST_MODIFIED_MILLISECONDS = (Time.now.to_i - 30 * 24 * 60 * 60) * 1000

INITIALS_PARAMETERS = {
  :server => TEST_SERVER,
  :repo_key => TEST_REPO_KEY,
  :folder_path => TEST_FOLDER_PATH,
  :user => TEST_USER,
  :password => TEST_PASSWORD
}

class UnitTestClientClass < Minitest::Test

  def setup
    super
    @artifactory = IKE::Artifactory::Client.new(**INITIALS_PARAMETERS)
  end

  def test_server_arg
    parameters = INITIALS_PARAMETERS
    parameters[:server] = 'some-fake-server'
    artifactory = IKE::Artifactory::Client.new(**parameters) # should not fail
    assert artifactory.server == 'some-fake-server'
  end

  def test_repo_key_arg
    parameters = INITIALS_PARAMETERS
    parameters[:repo_key] = 'some-fake-repo_key'
    artifactory = IKE::Artifactory::Client.new(**parameters) # should not fail
    assert artifactory.repo_key == 'some-fake-repo_key'
  end

  def test_user_arg
    parameters = INITIALS_PARAMETERS
    parameters[:user] = 'some-fake-user'
      artifactory = IKE::Artifactory::Client.new(**parameters) # should not fail
    assert artifactory.user == 'some-fake-user'
  end

  def test_password_arg
    parameters = INITIALS_PARAMETERS
    parameters[:password] = 'some-fake-password'
      artifactory = IKE::Artifactory::Client.new(**parameters) # should not fail
    assert artifactory.password == 'some-fake-password'
  end

  def test_server_attribute
    assert @artifactory.respond_to? :server
    assert @artifactory.respond_to? :server=
  end

  def test_repo_key_attribute
    assert @artifactory.respond_to? :repo_key
    assert @artifactory.respond_to? :repo_key=
  end

  def test_user_attribute
    assert @artifactory.respond_to? :user
    assert @artifactory.respond_to? :user=
  end

  def test_password_attribute
    assert @artifactory.respond_to? :password
    assert @artifactory.respond_to? :password=
  end

end

class UnitTestClientMethods < Minitest::Test

  def setup
    super
    @artifactory = IKE::Artifactory::Client.new(**INITIALS_PARAMETERS)
  end

  def test_not_ready
    artifactory = IKE::Artifactory::Client.new(**INITIALS_PARAMETERS)
    artifactory.password = nil
    refute artifactory.send :ready?
  end

  def test_ready
    artifactory = IKE::Artifactory::Client.new(**INITIALS_PARAMETERS)
    assert artifactory.send :ready?
  end

  def test_no_password
    exception = assert_raises IKE::Artifactory::IKEArtifactoryClientNotReady do
      artifactory = IKE::Artifactory::Client.new(**{
        :server => TEST_SERVER,
        :repo_key => TEST_REPO_KEY,
        :user => TEST_USER
      })
    end
    assert_equal('Required attributes are missing. IKEArtifactoryGem not ready.', exception.message)
  end

  def test_no_auth_data
    exception = assert_raises IKE::Artifactory::IKEArtifactoryClientNotReady do
      artifactory = IKE::Artifactory::Client.new(**{
        :server => TEST_SERVER,
        :repo_key => TEST_REPO_KEY,
      })
    end
    assert_equal('Required attributes are missing. IKEArtifactoryGem not ready.', exception.message)
  end

  def test_no_server
    exception = assert_raises IKE::Artifactory::IKEArtifactoryClientNotReady do
      artifactory = IKE::Artifactory::Client.new(**{
        :repo_key => TEST_REPO_KEY,
        :user => TEST_USER,
        :password => TEST_PASSWORD
      })
    end
    assert_equal('Required attributes are missing. IKEArtifactoryGem not ready.', exception.message)
  end

  def test_get_object_info_call_get_api
    mock_request = Minitest::Mock.new
    mock_request.expect :call,
                        true,
                        [:method => :get,
                         :url => @artifactory.server + '/artifactory/api/storage/' + @artifactory.repo_key + '/' + 'fake-object',
                         :user => @artifactory.user, :password => @artifactory.password]

    RestClient::Request.stub :execute, mock_request do
      @artifactory.get_object_info 'fake-object'
    end
    assert_mock mock_request
  end

  def test_get_object_info_return_nil_if_fail
    mock_response = Minitest::Mock.new
    mock_response.expect :code, 404
    mock_response.expect :to_str, '{ "test": "fake" }'

    RestClient::Request.stub :execute,
                             nil,
                             [mock_response, 'fake-request', 'fake-result'] do
      result = @artifactory.get_object_info 'fake-object'
      assert_nil result
    end
  end

  def test_get_object_info_json_parse_called
    mock_response = Minitest::Mock.new
    mock_response.expect :code, 200
    mock_response.expect :to_str, '{ "test": "fake" }'
    mock_json = Minitest::Mock.new
    mock_json.expect :call,
                     {"test" => "fake"},
                     ['{ "test": "fake" }']

    RestClient::Request.stub :execute,
                             nil,
                             [mock_response, 'fake-request', 'fake-result'] do
      JSON.stub :parse, mock_json do
        @artifactory.get_object_info 'fake-object'
      end
    end
    assert_mock mock_json
  end

  def test_get_object_info_return_json_parse_result
    mock_response = Minitest::Mock.new
    mock_response.expect :code, 200
    mock_response.expect :to_str, '{ "test": "fake" }'
    mock_json = Minitest::Mock.new
    mock_json.expect :call,
                     {"test" => "fake-fake##"},
                     ['{ "test": "fake" }']

    RestClient::Request.stub :execute,
                             nil,
                             [mock_response, 'fake-request', 'fake-result'] do
      JSON.stub :parse, mock_json do
        result = @artifactory.get_object_info 'fake-object'
        assert_equal({"test" => "fake-fake##"}, result)
      end
    end
  end

  def test_get_object_age_call_get_api
    mock_request = Minitest::Mock.new
    mock_request.expect :call,
                        true,
                        [:method => :get,
                         :url =>@artifactory.server + '/artifactory/api/storage/' + @artifactory.repo_key + '/' + 'fake-object',
                         :user => @artifactory.user, :password => @artifactory.password]

    RestClient::Request.stub :execute, mock_request do
      @artifactory.get_object_age 'fake-object'
    end
    assert_mock mock_request
  end

  def test_get_object_age_return_negative_if_fail
    mock_response = Minitest::Mock.new
    mock_response.expect :code, 404
    mock_response.expect :to_str, '{ "test": "fake" }'

    RestClient::Request.stub :execute,
                             nil,
                             [mock_response, 'fake-request', 'fake-result'] do
      result = @artifactory.get_object_age 'fake-object'
      assert_nil(result)
    end
  end

  def test_get_object_age_json_parse_called
    mock_response = Minitest::Mock.new
    mock_response.expect :code, 200
    mock_response.expect :to_str, '{ "test": "fake", "lastModified": "2021-09-14T12:27:00.10" }'
    mock_json = Minitest::Mock.new
    mock_json.expect :call,
                     { "test" => "fake", "lastModified" => "2021-09-14T12:27:00.10" },
                     ['{ "test": "fake", "lastModified": "2021-09-14T12:27:00.10" }']

    RestClient::Request.stub :execute,
                             nil,
                             [mock_response, 'fake-request', 'fake-result'] do
      JSON.stub :parse, mock_json do
        @artifactory.get_object_age 'fake-object'
      end
    end
    assert_mock mock_json
  end

  def test_get_object_age_call_time_with_last_updated
    mock_response = Minitest::Mock.new
    mock_response.expect :code, 200
    mock_response.expect :to_str, '{ "test": "fake", "lastModified": "2021-09-14T12:27:00.10" }'
    mock_time = Minitest::Mock.new
    mock_time.expect :call, Time.now, ['2021-09-14T12:27:00.10']

    RestClient::Request.stub :execute,
                             nil,
                             [mock_response, 'fake-request', 'fake-result'] do
      JSON.stub :parse, { 'uri' => 'fake-host', 'lastModified' => '2021-09-14T12:27:00.10'} do
        Time.stub :iso8601, mock_time do
          @artifactory.get_object_age 'fake-object'
        end
      end
    end
    assert_mock mock_time
  end

  def test_get_object_age_call_time_now
    mock_response = Minitest::Mock.new
    mock_response.expect :code, 200
    mock_response.expect :to_str, '{ "test": "fake", "lastModified": "2021-09-14T12:27:00.10" }'
    mock_time = Minitest::Mock.new
    mock_time.expect :call, Time.now, []

    RestClient::Request.stub :execute,
                             nil,
                             [mock_response, 'fake-request', 'fake-result'] do
      JSON.stub :parse, { 'uri' => 'fake-host', 'lastModified' => '2021-09-14T12:27:00.10'} do
        Time.stub :now, mock_time do
          @artifactory.get_object_age 'fake-object'
        end
      end
    end
    assert_mock mock_time
  end

  def test_get_object_age_return_days_subtract
    mock_response = Minitest::Mock.new
    mock_response.expect :code, 200
    mock_response.expect :to_str, '{ "test": "fake", "lastModified": "2021-09-14T12:27:00.10" }'

    RestClient::Request.stub :execute,
                             nil,
                             [mock_response, 'fake-request', 'fake-result'] do
      JSON.stub :parse, { 'uri' => 'fake-host', 'lastModified' => '2021-09-14T12:27:00.10'} do
        Time.stub :iso8601, (Time.now - (20*24*60*60)) do
          result = @artifactory.get_object_age 'fake-object'
          assert_equal 20, result
        end
      end
    end
  end

  def test_delete_object_call_get_api
    mock_request = Minitest::Mock.new
    mock_request.expect :call,
                        true,
                        [:method => :delete,
                         :url =>  "#{@artifactory.server}/artifactory/api/storage/#{@artifactory.repo_key}/fake-object",
                         :user => @artifactory.user, :password => @artifactory.password]

    RestClient::Request.stub :execute, mock_request do
      @artifactory.delete_object 'fake-object'
    end
    assert_mock mock_request
  end

  def test_delete_object_return_nil_if_fail
    mock_response = Minitest::Mock.new
    mock_response.expect :code, 404

    RestClient::Request.stub :execute,
                             nil,
                             [mock_response, 'fake-request', 'fake-result'] do
      result = @artifactory.delete_object 'fake-object'
      refute result
    end
  end

  def test_delete_object_return_object_deleted
    mock_response = Minitest::Mock.new
    mock_response.expect :code, 204
    mock_response.expect :to_str, '{ "test": "fake" }'
    mock_json = Minitest::Mock.new
    mock_json.expect :call,
                     {"test" => "fake"},
                     ['{ "test": "fake" }']

    RestClient::Request.stub :execute,
                             nil,
                             [mock_response, 'fake-request', 'fake-result'] do
      result = @artifactory.delete_object 'fake-object'
      assert result
    end
  end

  def test_get_directories_folder_path_parameter
    mock_request = Minitest::Mock.new
    mock_request.expect :call,
                        true,
                        [:method => :get,
                         :url =>  "#{@artifactory.server}/artifactory/api/storage/#{@artifactory.repo_key}/fake",
                         :user => @artifactory.user, :password => @artifactory.password]

    RestClient::Request.stub :execute, mock_request do
      @artifactory.get_subdirectories 'fake'
    end
    assert_mock mock_request
  end

  def test_get_directories_return_nil_if_not_connect
    mock_response = Minitest::Mock.new
    mock_response.expect :code, 401

    RestClient::Request.stub :execute,
                             nil,
                             [mock_response, 'fake1', 'fake2' ] do
      result = @artifactory.get_subdirectories 'fake-path'
      assert result.nil?
    end
  end

  def test_get_directories_return_empty_array
    mock_response = Minitest::Mock.new
    mock_response.expect :code, 200
    mock_response.expect :to_str, '{ "test": "fake" }'

    RestClient::Request.stub :execute,
                             nil,
                             [mock_response, 'fake1', 'fake2' ] do
      result = @artifactory.get_subdirectories 'fake-path'
      assert_instance_of Array, result
      assert_empty result
    end
  end

  def test_get_directories_json_parse_called
    mock_response = Minitest::Mock.new
    mock_response.expect :code, 200
    mock_response.expect :to_str, '{ "test": "fake" }'
    mock_json_parse = Minitest::Mock.new
    mock_json_parse.expect :call, {:fake => 'fake'}, ['{ "test": "fake" }']

    RestClient::Request.stub :execute,
                             nil,
                             [mock_response, 'fake1', 'fake2' ] do
      JSON.stub :parse, mock_json_parse do
        @artifactory.get_subdirectories 'fake-path'
      end
    end
    assert_mock mock_json_parse
  end

  def test_get_directories_loop_children_returns_uri
    mock_response = Minitest::Mock.new
    mock_response.expect :code, 200
    mock_response.expect :to_str, '{ "children": [{"uri": "/fake1", "folder": true},{"uri": "/fake2", "folder": true}] }'

    RestClient::Request.stub :execute,
                             nil,
                             [mock_response, 'fake1', 'fake2' ] do
      result = @artifactory.get_subdirectories 'fake-path'
      assert_includes result, 'fake1'
      assert_includes result, 'fake2'
    end
  end

  def test_get_directories_returns_only_folders
    mock_response = Minitest::Mock.new
    mock_response.expect :code, 200
    mock_response.expect :to_str, '{ "children": [{"uri": "/fake1", "folder": true},{"uri": "/fake2", "folder": false}] }'

    RestClient::Request.stub :execute,
                             nil,
                             [mock_response, 'fake1', 'fake2' ] do
      result = @artifactory.get_subdirectories 'fake-path'
      assert_includes result, 'fake1'
      refute_includes result, 'fake2'
    end
  end

  def test_get_children_call_get_api
    mock_request = Minitest::Mock.new
    mock_request.expect :call,
                        true,
                        [:method => :get,
                         :url => "#{@artifactory.server}:443/ui/api/v1/ui/nativeBrowser/#{@artifactory.repo_key}/fake-path",
                         :user => @artifactory.user, :password => @artifactory.password]

    RestClient::Request.stub :execute, mock_request do
      @artifactory.get_subdirectory_ages 'fake-path'
    end
    assert_mock mock_request
  end

  def test_get_children_return_nil_if_fail
    mock_response = Minitest::Mock.new
    mock_response.expect :code, 404
    mock_response.expect :to_str, '{ "children": [{"name": "fake1", "folder": true},{"name": "fake2", "folder": false}] }'

    RestClient::Request.stub :execute,
                             nil,
                             [mock_response, 'fake-request', 'fake-result'] do
      result = @artifactory.get_subdirectory_ages 'fake-path'
      assert_nil result
    end
  end

  def test_json_parse_called
    mock_response = Minitest::Mock.new
    mock_response.expect :code, 200
    mock_response.expect :to_str, '{ "children": [{"name": "fake1", "folder": true},{"name": "fake2", "folder": false}] }'
    mock_json_parse = Minitest::Mock.new
    mock_json_parse.expect :call,
                           { 'children' => [{ 'name' => 'fake1', "folder" => true, "lastModified" => TIME_LAST_MODIFIED_MILLISECONDS },
                                            { 'name' => 'fake2', "folder" => false, "lastModified" => TIME_LAST_MODIFIED_MILLISECONDS }]},
                           ['{ "children": [{"name": "fake1", "folder": true},{"name": "fake2", "folder": false}] }']

    RestClient::Request.stub :execute,
                             nil,
                             [mock_response, 'fake-request', 'fake-result'] do
      JSON.stub :parse, mock_json_parse do
        @artifactory.get_subdirectory_ages 'fake-path'
      end
    end
    assert_mock mock_json_parse
  end

  def test_for_each_children_return_a_hash_key
    mock_response = Minitest::Mock.new
    mock_response.expect :code, 200
    mock_response.expect :to_str, '{ "fake": "fake" }'
    object_info =  { 'children' => [
        { 'name' => 'fake1', "folder" => true, "lastModified" => TIME_LAST_MODIFIED_MILLISECONDS },
        { 'name' => 'fake2', "folder" => false, "lastModified" => TIME_LAST_MODIFIED_MILLISECONDS }]}

    RestClient::Request.stub :execute,
                             nil,
                             [mock_response, 'fake-request', 'fake-result'] do
      JSON.stub :parse, object_info do
        objects = @artifactory.get_subdirectory_ages 'fake-path'
        assert objects.has_key?('fake1')
        assert objects.has_key?('fake2')
      end
    end
  end

  def test_returned_object_value_is_days_old
    mock_response = Minitest::Mock.new
    mock_response.expect :code, 200
    mock_response.expect :to_str, '{ "fake": "fake" }'
    object_info =  { 'children' => [
      { 'name' => 'fake1', "folder" => true, "lastModified" => TIME_LAST_MODIFIED_MILLISECONDS },
      { 'name' => 'fake2', "folder" => false, "lastModified" => TIME_LAST_MODIFIED_MILLISECONDS }]}

    RestClient::Request.stub :execute,
                             nil,
                             [mock_response, 'fake-request', 'fake-result'] do
      JSON.stub :parse, object_info do
        objects = @artifactory.get_subdirectory_ages 'fake-path'
        assert_equal 30, objects['fake1']
        assert_equal 30, objects['fake2']
      end
    end
  end
end
