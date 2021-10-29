require "test_helper"

class UnitTestDockerCleaner < Minitest::Test

  def setup
    @artifactory = IKE::Artifactory::DockerCleaner.new(
      repo_host: 'https://artifactory.internetbrands.com',
      repo_key: 'avvo-docker-local',
      folder: 'avvo/amos',
      days_old: 30,
      tags_to_exclude: %w[fake1 fake2],
      user: 'user',
      password: 'password',
      most_recent_images: 10
    )
  end

  def test_repo_host
    assert @artifactory.repo_host == 'https://artifactory.internetbrands.com'
  end

  def test_repo_key
    assert @artifactory.repo_key == 'avvo-docker-local'
  end

  def test_folder
    assert @artifactory.folder == 'avvo/amos'
  end

  def test_days_old
    assert @artifactory.days_old == 30
  end

  def test_tags_to_exclude
    assert @artifactory.tags_to_exclude == %w[fake1 fake2]
  end

  def test_repo_host_attribute
    assert @artifactory.respond_to? :repo_host
    assert @artifactory.respond_to? :repo_host
  end

  def test_repo_key_attribute
    assert @artifactory.respond_to? :repo_key
    assert @artifactory.respond_to? :repo_key
  end

  def test_folder_attribute
    assert @artifactory.respond_to? :folder
    assert @artifactory.respond_to? :folder
  end

  def test_days_old_attribute
    assert @artifactory.respond_to? :days_old
    assert @artifactory.respond_to? :days_old=
  end

  def test_tags_to_exclude_attribute
    assert @artifactory.respond_to? :tags_to_exclude
    assert @artifactory.respond_to? :tags_to_exclude=
  end
end

class UnitTestDockerCleanerMethods < Minitest::Test

  def setup
    @docker_cleaner = IKE::Artifactory::DockerCleaner.new(
      repo_host: 'https://artifactory.internetbrands.com',
      repo_key: 'avvo-docker-local',
      folder: 'avvo/amos',
      days_old: 30,
      tags_to_exclude: %w[fake-x fake-y],
      user: 'user',
      password: 'password',
      most_recent_images: 2
    )
  end

  def test_call_get_images_with_repo_name
    mock_get_children = Minitest::Mock.new()
    mock_get_children.expect :call,
                             { 'fake' => 3 },
                             ['avvo/amos']


    @docker_cleaner.client.stub :get_images, mock_get_children do
      @docker_cleaner.cleanup!
    end
    assert_mock mock_get_children
  end

  def test_check_if_tag_is_included_in_exclude_list
    mock_exclude_list = Minitest::Mock.new()
    mock_exclude_list.expect :call,
                             true,
                             ['fake']

    @docker_cleaner.client.stub :get_images, { 'fake' => 3 } do
      @docker_cleaner.tags_to_exclude.stub :include?, mock_exclude_list do
        @docker_cleaner.cleanup!
      end
    end
    assert_mock mock_exclude_list
  end

  def test_if_tag_is_older_than_days_old_is_deleted
    docker_cleaner = IKE::Artifactory::DockerCleaner.new(
      repo_host: 'https://artifactory.internetbrands.com',
      repo_key: 'avvo-docker-local',
      folder: 'avvo/amos',
      days_old: 30,
      tags_to_exclude: %w[fake-x fake-y],
      user: 'user',
      password: 'password',
      most_recent_images: 2,
      actually_delete: true
    )

    mock_delete_object = Minitest::Mock.new()
    mock_delete_object.expect :call,
                              true,
                              ["#{docker_cleaner.folder}/fake5"]
    docker_cleaner.client.stub :get_images, {
      'fake1' => 21, 'fake2' => 22, 'fake3' => 23, 'fake4' => 24,  'fake5' => 35, } do
      docker_cleaner.client.stub :delete_object, mock_delete_object do
        docker_cleaner.cleanup!
      end
    end
    assert_mock mock_delete_object
  end

  def test_if_tag_is_not_deleted_by_default
    mock_delete_object = Minitest::Mock.new()
    mock_delete_object.expect :call,
                              true,
                              ["#{@docker_cleaner.folder}/fake5"]
    @docker_cleaner.client.stub :get_images, {
      'fake1' => 21, 'fake2' => 22, 'fake3' => 23, 'fake4' => 24,  'fake5' => 35, } do
      @docker_cleaner.client.stub :delete_object, mock_delete_object do
        @docker_cleaner.cleanup!
      end
    end

    begin
      mock_delete_object.verify
    rescue MockExpectationError
      pass
    rescue
      assert(false , 'Test fail for unknown reasons.')
    end
  end

  def test_images_are_excluded
    mock_delete_object = Minitest::Mock.new()
    mock_delete_object.expect :call,
                              true,
                              ["#{@docker_cleaner.folder}/fake3"]
    mock_delete_object.expect :call,
                              true,
                              ["#{@docker_cleaner.folder}/fake4"]
    mock_delete_object.expect :call,
                              true,
                              ["#{@docker_cleaner.folder}/fake5"]
    @docker_cleaner.client.stub :get_images, {
      'fake-x' => 71, 'fake-y' => 62, 'fake3' => 90, 'fake4' => 91,  'fake5' => 92, } do
      @docker_cleaner.client.stub :delete_object, mock_delete_object do
        result = @docker_cleaner.cleanup!
        refute_includes result, 'fake-x'
        refute_includes result, 'fake-y'
        assert_includes result, 'fake3'
        assert_includes result, 'fake4'
        assert_includes result, 'fake5'
      end
    end
  end

  def test_images_are_most_recent
    mock_delete_object = Minitest::Mock.new()
    mock_delete_object.expect :call,
                              true,
                              ["#{@docker_cleaner.folder}/fake3"]
    mock_delete_object.expect :call,
                              true,
                              ["#{@docker_cleaner.folder}/fake4"]
    mock_delete_object.expect :call,
                              true,
                              ["#{@docker_cleaner.folder}/fake5"]
    @docker_cleaner.client.stub :get_images, {
      'fake-a' => 11, 'fake-b' => 12, 'fake3' => 31, 'fake4' => 32,  'fake5' => 33, } do
      @docker_cleaner.client.stub :delete_object, mock_delete_object do
        result = @docker_cleaner.cleanup!
        refute_includes result, 'fake-a'
        refute_includes result, 'fake-b'
      end
    end
  end

  def test_images_are_removed
    mock_delete_object = Minitest::Mock.new()
    mock_delete_object.expect :call,
                              true,
                              ["#{@docker_cleaner.folder}/fake3"]
    mock_delete_object.expect :call,
                              true,
                              ["#{@docker_cleaner.folder}/fake4"]
    mock_delete_object.expect :call,
                              true,
                              ["#{@docker_cleaner.folder}/fake5"]
    @docker_cleaner.client.stub :get_images, {
      'fake-a' => 11, 'fake-b' => 12, 'fake3' => 31, 'fake4' => 32,  'fake5' => 33, } do
      @docker_cleaner.client.stub :delete_object, mock_delete_object do
        result = @docker_cleaner.cleanup!
        assert_includes result, 'fake3'
        assert_includes result, 'fake4'
        assert_includes result, 'fake5'
      end
    end
  end
end
