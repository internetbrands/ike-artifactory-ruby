require 'uri'
require 'logger'

module IKE
  module Artifactory

    class DockerCleaner
      attr_accessor :repo_host
      attr_accessor :repo_key
      attr_accessor :folder
      attr_accessor :days_old
      attr_accessor :tags_to_exclude

      attr_reader :client  # is not tested
      attr_reader :most_recent_images  # is not tested
      attr_reader :logger  # is not tested. Used for testing
      attr_reader :actually_delete

      def initialize(repo_host:, repo_key:, folder:, days_old:,
                     tags_to_exclude:, user:, password:, most_recent_images:,
                     log_level: ::Logger::INFO, actually_delete: false)

        @repo_host = repo_host
        @repo_key = repo_key
        @folder = folder
        @days_old = days_old
        @tags_to_exclude = tags_to_exclude || []
        @most_recent_images = most_recent_images

        @actually_delete = actually_delete

        @client = IKE::Artifactory::Client.new(
          :server => repo_host,
          :repo_key => repo_key,
          :user => user,
          :password => password
        )

        @logger = Logger.new(STDOUT)
        logger.level = log_level
      end

      def cleanup!
        deleted_images = []
        tags = client.get_images(folder).sort_by { |_k,v| v }.to_h

        too_new_to_delete = tags.keys[0...most_recent_images]

        logger_prefix = "#{repo_host}/#{repo_key}"

        tags.each do | tag, tag_days_old |

          logger.debug "#{logger_prefix}: examining #{tag}"

          if tags_to_exclude.include?(tag)
            logger.info "#{logger_prefix}: tag #{tag} is explicitly excluded from cleanup"
            next
          end

          if too_new_to_delete.include?(tag)
            logger.info "#{logger_prefix}: tag #{tag} is one of the #{most_recent_images} most recent tags, preserving"
            next
          end

          if tag_days_old < days_old
            logger.info "#{logger_prefix}: tag #{tag} is less than #{days_old} days old, preserving"
            next
          end

          logger.info "#{logger_prefix}: removing tag #{tag}"
          if actually_delete
            client.delete_object "#{folder}/#{tag}"
          else
            logger.info("#{logger_prefix}: Not actually deleting #{tag} because actually_delete is falsy")
          end
          deleted_images.append(tag)
        end
        deleted_images
      end
    end
  end
end
