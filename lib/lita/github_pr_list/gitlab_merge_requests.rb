require 'rest_client'

module Lita
  module GithubPrList
    class GitlabMergeRequests
      attr_accessor :raw_response, :redis

      def initialize(args = {})
        self.redis = args.fetch(:redis, nil)
      end

      # Gitlab merge events don't always trigger the web hook. This will remove merged MRs from redis
      def rectify
        if local_merge_requests?
          closed_merge_requests.each do |closed_merge_request|
            Lita::GithubPrList::MergeRequest.new({ id: closed_merge_request.id, state: 'not_open', redis: redis }).handle
          end
        end
      end

    private

      def gitlab_data
        self.raw_response = RestClient::Request.execute(
          method: :get,
          url: "https://gitlab.corp.ads/api/v3/projects/1/merge_requests",
          headers: {
            accept: 'application/xml',
            content_type: 'application/xml',
            'PRIVATE-TOKEN' => Lita.config.handlers.github_pr_list.gitlab_api_key
          },
          verify_ssl: OpenSSL::SSL::VERIFY_NONE
        )
      end

      def closed_merge_requests
        Builders::MergeRequestBuilder.new(merge_request_data: JSON.parse(gitlab_data)).closed
      end

      def local_merge_requests?
        redis.keys("gitlab_mr*").any?
      end
    end
  end
end
