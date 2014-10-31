module Lita
  module GithubPrList
    class PullRequestOpenMessageHook
      attr_accessor :response, :request, :redis, :payload, :pull_request_owner, :title, :repo_name

      def initialize(params = {})
        self.response = params.fetch(:response, nil)
        self.request = params.fetch(:request, nil)
        self.redis = params.fetch(:redis, nil)

        raise "invalid params in #{self.class.name}" if response.nil? || request.nil? || redis.nil?
        require 'pry'
        binding.pry
        # https://developer.github.com/v3/activity/events/types/#pullrequestevent
        self.payload = JSON.parse(request.body.read)
        self.pull_request_owner = redis.get("alias:#{payload["pull_request"]["user"]["login"]}") || payload["pull_request"]["user"]["login"]
        self.title = payload["pull_request"]["title"]
        self.repo_name = payload["pull_request"]["head"]["repo"]["full_name"]
      end

      def message
        "@#{pull_request_owner} opened pull request: '#{title}' in '#{repo_name}'"
      end
    end
  end
end
