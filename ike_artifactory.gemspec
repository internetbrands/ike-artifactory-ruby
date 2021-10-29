lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "ike_artifactory/version"


# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'ike-artifactory'
  s.version     = IKE::Artifactory::VERSION
  s.authors     = ['Nick Marden', 'Jack Newton', 'Vicente Ramos Garcia']
  s.email       = %w[nmarden@avvo.com jnewton@avvo.com vramosgarcia@avvo.com]
  s.homepage    = 'https://github.com/internetbrands/ike-artifactory-ruby'
  s.summary     = 'Provides an object-oriented interface to Artifactory API.'
  s.description = 'Ruby gem for managing objects in Artfactory, particularly for cleaning up old Docker images'
  s.license     = 'MIT'
  s.metadata['allowed_push_host'] = 'https://rubygems.org'
  s.files = Dir['{bin,lib}/**/*', 'Rakefile', 'README.md']
  s.add_dependency 'rake'
  s.add_dependency 'rest-client'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'pry-byebug'
end
