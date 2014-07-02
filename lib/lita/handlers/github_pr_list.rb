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

      http.get "/comment_hook", :comment_hook

      def comment_hook(request, response)
        rooms = Lita.config.adapter.rooms
        rooms ||= [:all]
        rooms.each do |room|
          target = Source.new(room: room)
          robot.send_message(target, 'test11111')
        end

        response.body << "Nothing to see here..."
      end

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
        issues = github_client.org_issues(ENV['GITHUB_ORG'], { filter: 'all', sort: 'created' })

        issues.each do |i|
          github_pull_requests << i if i.pull_request
        end
      end

      def build_summary
        self.summary = "I found #{github_pull_requests.count} open pull requests for #{ENV['GITHUB_ORG']}"

        github_pull_requests.each do |pr_issue|
          status = repo_status("#{pr_issue.repository.full_name}", pr_issue.number)
          self.summary = summary + "\n#{pr_issue.repository.name} #{status} #{pr_issue.title} #{pr_issue.pull_request.html_url}"
        end
      end

      def repo_status(repo_full_name, issue_number)
        status = "(new)"
        comments = github_client.issue_comments(repo_full_name, issue_number, { direction: 'asc', sort: 'created' })

        if !comments.empty?
          comments.each do |c|
            body = c.body

            case body
            when pass_regex
              status = "(elephant)(elephant)(elephant)"
            when review_regex
              status = "(book)"
            when fail_regex
              status = "(poop)"
            when fixed_regex
              status = "(wave)"
            end
          end
        end

        status
      end
    end

    Lita.register_handler(GithubPrList)
  end
end