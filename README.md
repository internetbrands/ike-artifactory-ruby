# IKE Artifactory

This gem provides an object-oriented interface to Artifactory API for managing objects in Artfactory,
particularly for cleaning up old Docker images.

## Classes

This gem implements two classes:

* `IKE::Artifactory::Client`: Interfaces with the Artifactory API
* `IKE::Artifactory::DockerCleaner`: Uses `IKE::Artifactory::Client` to implement a single method called `cleanup!` that lets you specify a path in Artifactory that has Docker container images. The `cleanup!` method will delete all images except the following:
  * a list of tags to be excluded (`tags_to_exclude`)
  * any images less than a certain age (`days_old`)
  * any the most recent N images, regardless of age (`most_recent_images`)

## Utility scripts

Utility scripts that use these classes can be found in the `bin` directory:

* `cleaner.rb` - an interface to `IKE::Artifactory::DockerCleaner`; see [README.cleaner.md](README.cleaner.md)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ike-artifactory-ruby'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install ike-artifactory-ruby

## Usage

### IKE::Artifactory::Client

To create an instance of IKE::Artifactory::Client you will need to provide next parameters:
* **server**: Artifactory server URL. 
* **repo_key**: Repository in Artifactory server.
* **user**: Username to be used to access repository.
* **password**: User's password.

#### Example
```ruby
require 'ike-artifactory'

artifactory_client = IKE::Artifactory::Client.new(
        :server => 'https://artifactory.mydomain.com',
        :repo_key => 'repo-key-example',
        :user => 'Ana',
        :password => 'supersecret'
)

object_info = artifactory_client.get_object_info 'path/to/object'
```

The output will be a hash with the proprieties of the queried object:
```ruby
{"repo"=>"repo-key-example",
 "path"=>"path/to/object",
 "created"=>"2021-05-25T15:27:21.592-07:00",
 "createdBy"=>"some-user",
 "lastModified"=>"2021-05-25T15:27:21.592-07:00",
 "modifiedBy"=>"other-userr",
 "lastUpdated"=>"2021-05-25T15:27:21.592-07:00",
 "children"=>
  [{"uri"=>"/manifest.json", "folder"=>false},
   {"uri"=>
     "/sha256__4f07dd360c1b7e40c438e6437b2044bc31b4f6e5cf36b09a06b0c67e23dfc69d",
    "folder"=>false},
   {"uri"=>
     "/sha256__70fb9965a23f2226fef622992fdf507b8333c61d68259766d4721cc4ba1e5dae",
    "folder"=>false},
   {"uri"=>
     "/sha256__e0f9e11d6f9b3f5af2915fd4839ea0cd268ddccce28a788f54687b6a494770bb",
    "folder"=>false}],
 "uri"=>
  "https://artifactory.mydomain.com:443/artifactory/api/storage/repo-key-example/path/to/object"}
```

#### Methods

##### `delete_object(path)`
Returns `true` if the object pointed by path was successfully deleted, otherwise `false`

##### `get_subdirectories(path)`
Returns a list of subdirectories of the specified `path`.

##### `get_object_age(path)`
Returns the age of the object specified by `path`, or -1 if the age of the object could not be determined (for example, if it does not exist).

##### `get_object_info(path)`
Returns a hash with the proprieties of the queried object.

##### `get_subdirectory_ages(path)`
Returns a hash whose keys are the names of the subdirectories of `path`, and whose values are the `lastModified` age in days of the directory in question.

##### `get_images(path)`
Returns a hash whose keys are the names (tags) of the Docker images found in `path`, and whose values are the age of the Docker image in question. An entry in `path` is considered to be a Docker image if it contains the file identified by the `IKE::Artifactory::Client::IMAGE_MANIFEST` constant, which is `manifest.json`.

### IKE::Artifactory::DockerCleaner

The constructor arguments of IKE::Artifactory::DockerCleaner are the following:
* `repo_host`: The URL of the Artifactory host, without the repo key included
* `repo_key` The repository to be cleaned
* `folder`: The repository path to be cleaned. `cleanup!` only cleans a single path (directory) and does not recurse
* `days_old`: The cutoff age for deletion of images. Any images less that `days_old` old will not be cleaned up.
* `most_recent_images`: The number of most recent container images to keep, regardless of age
* `tags_to_exclude`: List of Docker container tags to be excluded from deletion, regardless of age
* `user`: The username to be used to access repository
* `password`: User's password.
* `log_level` (optional): Logging verbosity, from the `Logger` Ruby core class. Defaults to ::Logger::INFO.
* `actually_delete` (optional): Whether to actually delete the images meeting the deletion criteria (truthy) or simply provide output about what would happen (falsy). Defaults to `false`.

Returns an array of image tags that would have been deleted (`actually_delete` = `false`) or were deleted (`actually_delete` = `true`):

```ruby
['tag-x', 'tag-y', 'tag-z']
```

#### Example
```ruby
require 'ike-artifactory'

images_to_delete = IKE::Artifactory::DockerCleaner.new(
        :server => 'https://artifactory.mydomain.com',
        :repo_key => 'repo-key-example',
        :folder => 'path/to/folder',
        :days_old => 30,
        :most_recent_images => 5,
        :tags_to_exclude => ['tag1', 'tag2', 'tag3'],
        :user => 'Ana',
        :password => 'supersecret'
).cleanup!

puts "Not actually deleting images, but if I did I would have deleted these:"
images_to_delete.each do |i|
  puts "  #{i}"
end
```
