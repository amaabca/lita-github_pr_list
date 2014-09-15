module Lita
  module GithubPrList
    class MergeRequest
      attr_accessor :id, :title, :state, :redis

      def initialize(params = {})
        self.id = params[:id]
        self.title = params[:title]
        self.state = params[:state]
        self.redis = params[:redis]
      end

      def open?
        state == 'opened'
      end

      def handle
        if open?
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
        redis.set("gitlab_mr_#{id}", message)
      end

      def remove_merge_request
        redis.del("gitlab_mr_#{id}")
      end
    end
  end
end