module Lita
  module GithubPrList
    class CheckList
      attr_accessor :request, :response, :payload, :redis, :comment_body, :comment_id, :issue_owner,
                  :issue_title, :issue_html_url, :repo_name, :github_token, :github_client

      def initialize(params = {})
        self.github_token = params.fetch(:github_token, nil)
        self.response = params.fetch(:response, nil)
        self.request = params.fetch(:request, nil)
        self.redis = params.fetch(:redis, nil)

        raise "invalid params in #{self.class.name}" if response.nil? || request.nil? || redis.nil?

        self.github_client = Octokit::Client.new(access_token: github_token, auto_paginate: true)

        list = "- [ ] Change log
                - [ ] Demo page
                - [ ] Product owner signoff
                - [ ] Merge into master
                - [ ] deploy to production "

        # https://developer.github.com/v3/activity/events/types/#issuecommentevent
        self.payload = JSON.parse(request.body.read)
        self.comment_body = "#{payload["comment"]["body"]} #{list}"
        self.comment_id = payload["comment"]["id"]
        self.issue_owner = payload["pull_request"]["user"]["login"]
        self.issue_title = payload["pull_request"]["title"]
        self.issue_html_url = payload["pull_request"]["html_url"]
        self.repo_name = payload["pull_request"]["head"]["full_name"]
      end

      def message
        edit_comment_response = github_client.update_comment("octokit/octokit.rb", comment_id.to_i, comment_body)
        return nil if edit_comment_response.status != 200
        "@#{issue_owner} check list was added to your pull request: #{issue_title} #{issue_html_url}"
      end
    end
  end
end
