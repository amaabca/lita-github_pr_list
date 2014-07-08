require "lita"
require "octokit"
require "json"

module Lita
  module Handlers
    class GithubPrList < Handler
      attr_accessor :github_client, :organization_repos, :github_pull_requests, :summary

      route(/pr list/i, :list_org_pr, command: true, help: {
        "pr list" => "List open pull requests for an organization."
      })

      route(/pr alias user (\w*) (\w*)/i, :alias_user, command: true, help: {
        "pr alias user <Github Username> <Hipchat Username>" => "Create an alias to match a Github username to a Hipchat Username."
      })

      http.post "/comment_hook", :comment_hook

      def initialize(robot)
        super
        self.github_client = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'], auto_paginate: true)
        self.github_pull_requests = []
      end

      def list_org_pr(response)
        get_pull_requests
        build_summary

        response.reply summary
      end

      def alias_user(response)
        Lita::GithubPrList::AliasUser.new({ response:response, redis: redis }).create_alias
      end

      def comment_hook(request, response)
        message = Lita::GithubPrList::CommentHook.new({ request: request, response: response, redis: redis }).message

        rooms = Lita.config.adapter.rooms
        rooms ||= [:all]
        rooms.each do |room|
          target = Source.new(room: room)
          robot.send_message(target, message) unless message.nil?
        end

        response.body << "Nothing to see here..."
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
        comments = github_client.issue_comments(repo_full_name, issue_number, { direction: 'asc', sort: 'created' })

        status = { emoji: "(new)", status: "New" }
        if !comments.empty?
          comments.each do |c|
            status = Lita::GithubPrList::Status.new({comment: c.body, status: status}).comment_status
          end
        end

        status[:emoji]
      end
    end

    Lita.register_handler(GithubPrList)
  end
end