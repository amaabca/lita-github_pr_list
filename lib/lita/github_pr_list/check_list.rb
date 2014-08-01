module Lita
  module GithubPrList
    class CheckList
      attr_accessor :request, :response, :payload, :redis, :issue_body

      def initialize(params = {})
        self.response = params.fetch(:response, nil)
        self.request = params.fetch(:request, nil)
        self.redis = params.fetch(:redis, nil)

        raise "invalid params in #{self.class.name}" if response.nil? || request.nil? || redis.nil?

        list = "- [ ] Change log
                - [ ] Demo page
                - [ ] Product owner signoff
                - [ ] Merge into master
                - [ ] deploy to production "

        # https://developer.github.com/v3/activity/events/types/#issuecommentevent
        self.payload = JSON.parse(request.body.read)
        self.issue_body = "#{payload["comment"]["body"]} #{list}"
        self.comment_id = payload["comment"]["id"]
        self.issue_owner = payload["pull_request"]["user"]["login"]
        self.issue_title = payload["pull_request"]["base"]["name"]
        self.issue_html_url = payload["pull_request"]["issue_url"]
      end

      def message
        if payload[action] == "created" do
          #PATCH /repos/:owner/:repo/issues/comments/:id
          url = "https://api.github.com/repos/#{issue_owner}/#{issue_title}/issues/comments/#{comment_id}"
          response = RestClient.post url, body: issue_body
          return nil if response.status != 200
          "@#{issue_owner} check list added to your pull request: #{issue_title} has passed. #{issue_html_url}"
        end
    end
  end
end
