require 'test_helper'

class DockerCleanerClassTest < Minitest::Test

  def test_can_create_object
    IKE::Artifactory::DockerCleaner.new(
      repo_url: 'https://artifactory.internetbrands.com/artifactory/avvo-docker-local/avvo/amos',
      days_old: 30,
      tags_to_exclude: %w[fake1 fake2],
      user: ENV['TEST_USER'],
      password: ENV['TEST_PASSWORD'],
      most_recent_images: 10
    )
  end

end
