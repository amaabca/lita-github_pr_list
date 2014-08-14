module Lita
  module GithubPrList
    class CheckList
      attr_accessor :request, :response, :payload, :redis, :repo_name, :comment_body,
                    :title, :id, :github_token, :github_client

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
                - [ ] Deploy to production "

        self.payload = JSON.parse(request.body.read)
        self.repo_name = payload["pull_request"]["head"]["repo"]["full_name"]
        self.comment_body = "#{payload["pull_request"]["body"]} #{list}"
        self.title = payload["pull_request"]["title"]
        self.id = payload["number"]

        github_client.update_pull_request(repo_name, id, title, comment_body, 'open') if payload["action"] == "opened"
      end
    end
  end
end
