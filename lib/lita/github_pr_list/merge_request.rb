require "octokit"

module Lita
  module GithubPrList
    class MergeRequest
      attr_accessor :id, :title, :state, :redis

      def initialize(args = {})
        self.id = args['id']
        self.title = args['title']
        self.state = args['state']
        self.redis = args[:redis]
      end

      def open?
        state == 'opened'
      end

      def handle
        if merge_request.open?
          add_merge_request
        else
          remove_merge_request
        end
      end

    private

      def url
        "https://gitlab.corp.ads/ama/#{project}/merge_requests/#{id}"
      end

      def project
        'rails_envs'
      end

      def emoji
        "(new)"
      end

      def message
        "#{project} #{emoji} #{title} #{url}"
      end

      def add_merge_request
        redis.lpush("gitlab_mr_#{id}", message)
      end

      def remove_merge_request
        redis.lrem("gitlab_mr_#{id}", 0, message)
      end
    end
  end
end