require "octokit"

module Lita
  module GithubPrList
    class WebHook
      attr_accessor :web_hook, :github_client, :github_organization, :github_pull_requests

      def initialize(params = {})
        github_token = params.fetch(:github_token, nil)
        self.github_organization = params.fetch(:github_organization, nil)
        self.web_hook = params.fetch(:web_hook, nil)

        raise "invalid params in #{self.class.name}" if github_token.nil? || github_organization.nil? || web_hook.nil?

        self.github_client = Octokit::Client.new(access_token: github_token, auto_paginate: true)
      end

      def add_hooks
        github_client.repositories(github_organization).each do |repo|
          config = { url: "#{web_hook}", content_type: "json" }
          events = { events: ["issue_comment"] }

          github_client.create_hook(repo.full_name, "web", config, events)
        end
      end

      def remove_hooks
        github_client.repositories(github_organization).each do |repo|
          github_client.hooks(repo.full_name).each do |hook|
            if hook.config.url == web_hook
              github_client.remove_hook(repo.full_name, hook.id)
            end
          end
        end
      end

    end
  end
end