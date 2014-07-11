require "octokit"

module Lita
  module GithubPrList
    class PullRequest
      attr_accessor :github_client, :github_organization, :github_pull_requests,
                    :summary, :response

      def initialize(params = {})
        self.response = params.fetch(:response, nil)
        github_token = params.fetch(:github_token, nil)
        self.github_organization = params.fetch(:github_organization, nil)
        self.github_pull_requests = []

        raise "invalid params in #{self.class.name}" if response.nil? || github_token.nil? || github_organization.nil?

        self.github_client = Octokit::Client.new(access_token: github_token, auto_paginate: true)
      end

      def list
        get_pull_requests
        build_summary

        response.reply summary
      end

    private
      def get_pull_requests
        # Grab the issues and sort out the pull request issues
        issues = github_client.org_issues(github_organization, { filter: 'all', sort: 'created' })

        issues.each do |i|
          github_pull_requests << i if i.pull_request
        end
      end

      def build_summary
        self.summary = "I found #{github_pull_requests.count} open pull requests for #{github_organization}"

        github_pull_requests.each do |pr_issue|
          status = repo_status("#{pr_issue.repository.full_name}", pr_issue.number)
          self.summary += "\n#{pr_issue.repository.name} #{status} #{pr_issue.title} #{pr_issue.pull_request.html_url}"
        end
      end

      def repo_status(repo_full_name, issue_number)
        status = { emoji: "(new)", status: "New" }

        comments(repo_full_name, issue_number).each do |c|
          status = Lita::GithubPrList::Status.new(comment: c.body, status: status).comment_status
        end

        status[:emoji]
      end

      def comments(repo_full_name, issue_number, options = nil)
        github_options = options || { direction: 'asc', sort: 'created' }
        github_client.issue_comments(repo_full_name, issue_number, github_options)
      end
    end
  end
end