require "octokit"

module Lita
  module GithubPrList
    class WebHook
      attr_accessor :web_hook, :github_client, :github_organization, :github_pull_requests, :response

      def initialize(params = {})
        github_token = params.fetch(:github_token, nil)
        self.github_organization = params.fetch(:github_organization, nil)
        self.web_hook = params.fetch(:web_hook, nil)
        self.response = params.fetch(:response, nil)

        if github_token.nil? || github_organization.nil? || web_hook.nil? || response.nil?
          raise "invalid params in #{self.class.name}"
        end

        self.github_client = Octokit::Client.new(access_token: github_token, auto_paginate: true)
      end

      def add_hooks
        response.reply "Adding webhooks to #{github_organization}, this may take awhile..."
        github_client.organization_repositories(github_organization, { type: 'all' }).each do |repo|
          begin
            create_hook(repo.full_name)
          rescue => ex
            if ex.errors.first[:message] == "Hook already exists on this repository"
              next
            end
          end
        end

        response.reply "Finished adding webhooks to #{github_organization}"
      end

      def remove_hooks
        response.reply "Removing #{web_hook} webhooks from #{github_organization}, this may take awhile..."

        github_client.organization_repositories(github_organization, { type: 'all' }).each do |repo|
          github_client.hooks(repo.full_name).each do |hook|
            if hook.config.url == web_hook
              github_client.remove_hook(repo.full_name, hook.id)
            end
          end
        end

        response.reply "Finished removing webhooks from #{github_organization}"
      end

    private

      def create_hook(repo_full_name)
        config = { url: "#{web_hook}", content_type: "json" }
        events = { events: ["issue_comment"] }

        github_client.create_hook(repo_full_name, "web", config, events)
      end

    end
  end
end
