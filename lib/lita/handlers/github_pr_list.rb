require "lita"
require "octokit"
require "hashie"

module Lita
  module Handlers
    class GithubPrList < Handler
      attr_accessor :github_client, :organization_repos, :github_pull_requests, :summary
      attr_accessor :pass_regex, :review_regex, :fail_regex, :fixed_regex

      route(/pr list/i, :list_org_pr, command: true, help: {
        "pr list" => "List open pull requests for an organization."
      })

      def initialize(robot)
        super
        self.github_client = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'], auto_paginate: true)
        self.github_pull_requests = []
        self.pass_regex = /:elephant: :elephant: :elephant:/
        self.review_regex = /:book:/
        self.fail_regex = /:poop:/
        self.fixed_regex = /:wave:/
      end

      def list_org_pr(response)
        get_pull_requests
        build_summary

        response.reply summary
      end

    private
      def get_pull_requests
        # Grab the issues and sort out the pull request issues
        issues = github_client.org_issues('amaabca', {filter: 'all', sort:'created'})

        issues.each do |i|
          github_pull_requests << i if i.pull_request
        end
      end

      def build_summary
        self.summary = "I found #{github_pull_requests.count} open pull requests for 'amaabca'"

        github_pull_requests.each do |pr_issue|
          status = repo_status("#{pr_issue.repository.full_name}", pr_issue.number)
          self.summary = summary + "\n#{pr_issue.repository.name} #{status} #{pr_issue.title} #{pr_issue.pull_request.html_url}"
        end
      end

      def repo_status(repo_name, issue_number)
        status = ""
        comments = github_client.issue_comments(repo_name, issue_number, { direction: 'asc', sort:'created' })

        if !comments.empty?
          comments.each do |  c|
            body = c.body
            if body =~ pass_regex
              status = "(elephant)(elephant)(elephant)"
            elsif body =~ review_regex
              status = "(book)"
            elsif body =~ fail_regex
              status = "(poop)"
            elsif body =~ fixed_regex
              status = "(wave)"
            end
          end
        else
          status = "(new)"
        end

        status
      end
    end

    Lita.register_handler(GithubPrList)
  end
end