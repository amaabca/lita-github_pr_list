module Lita
  module GithubPrList
    class PullRequestOpenMessageHook
      attr_accessor :response, :request, :redis, :payload, :pull_request_owner, :title, :repo_name, :pull_request_status, :pull_request_html_url, :statuses

      def initialize(params = {})
        self.statuses = %w(opened)
        self.response = params.fetch(:response, nil)
        self.request = params.fetch(:request, nil)
        self.redis = params.fetch(:redis, nil)

        raise "invalid params in #{self.class.name}" if response.nil? || request.nil? || redis.nil?

        # https://developer.github.com/v3/activity/events/types/#pullrequestevent
        self.payload = JSON.parse(request.body.read)
        self.pull_request_status = payload["action"]
        self.pull_request_owner = redis.get("alias:#{payload["pull_request"]["user"]["login"]}") || payload["pull_request"]["user"]["login"]
        self.title = payload["pull_request"]["title"]
        self.repo_name = payload["pull_request"]["head"]["repo"]["full_name"]
        self.pull_request_html_url = payload["pull_request"]["html_url"]
      end

      def message
        if statuses.include? pull_request_status
          "@#{pull_request_owner} #{pull_request_status} pull request: '#{title}' in '#{repo_name}'. #{pull_request_html_url}"
        end
      end
    end
  end
end
