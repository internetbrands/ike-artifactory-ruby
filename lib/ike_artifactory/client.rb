require 'time'
require 'json'
require 'rest-client'
require 'uri'
require 'pry-byebug'
require 'logger'

module IKE
  module Artifactory
    class Client

      IMAGE_MANIFEST = 'manifest.json'

      attr_accessor :server
      attr_accessor :repo_key
      attr_accessor :folder_path
      attr_accessor :user
      attr_accessor :password

      def initialize(**args)
        @server = args[:server]
        @repo_key = args[:repo_key]
        @user = args[:user]
        @password = args[:password]

        raise IKEArtifactoryClientNotReady.new(msg = 'Required attributes are missing. IKEArtifactoryGem not ready.') unless self.ready?
      end

      def delete_object(path)
        fetch(path, method: :delete) do |response, request, result|
          response.code == 204
        end
      end

      def get_subdirectories(path)
        get(path) do |response|
          (response['children'] || []).select do |c|
            c['folder']
          end.map do |f|
            f['uri'][1..]
          end
        end
      end

      def get_object_age(path)
        get(path) do |response|
          ( ( Time.now - Time.iso8601(response['lastModified']) ) / (24*60*60) ).to_int
        end
      end

      def get_object_info(path)
        get(path)
      end

      def get_subdirectory_ages(path)
        get(path, prefix: "#{server}:443/ui/api/v1/ui/nativeBrowser/#{repo_key}") do |response|
          (response['children'] || []).each_with_object({}) do |child, memo|
            days_old = ( ( Time.now.to_i - (child['lastModified']/1000) ) / (24*60*60) ).to_int
            memo[child['name']] = days_old
            memo
          end
        end
      end

      def get_images(path)
        get_subdirectory_ages(path).select do |(folder, _age)|
          get_object_info([path, folder, IMAGE_MANIFEST].join('/'))
        end
      end

      private

      def ready?
        if ([server, repo_key].include? nil ) || ([user, password].include? nil )
          return false
        end
        true
      end

      def fetch(path, method: :get, prefix: nil)
        retval = nil # Work around Object#stub stomping on return values

        prefix ||= "#{server}/artifactory/api/storage/#{repo_key}"
        if method == :delete
          prefix = "#{server}/artifactory/#{repo_key}"
        end

        RestClient::Request.execute(
          :method => method,
          :url => "#{prefix}/#{path}",
          :user => user,
          :password => password
        ) do |response, request, result|
          retval =
            if block_given?
              yield response, request, result
            else
              [response, request, result]
            end
        end

        retval
      end

      def get(path, prefix: nil)
        fetch(path, prefix: prefix) do |response, request, result|
          if response.code == 200
            obj = JSON.parse(response.to_str)
            if block_given?
              yield obj
            else
              obj
            end
          end
        end
      end

    end
  end
end
