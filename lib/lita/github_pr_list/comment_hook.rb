module Lita
  module GithubPrList
    class CommentHook
      attr_accessor :request, :response, :payload, :commenter, :issue_owner, :issue_title, :issue_body, :status,
                    :issue_html_url, :redis, :github_organization, :github_client

      def initialize(params = {})
        self.response = params.fetch(:response, nil)
        self.request = params.fetch(:request, nil)
        self.redis = params.fetch(:redis, nil)
        self.github_organization = params.fetch(:github_organization, nil)
        github_token = params.fetch(:github_token, nil)
        self.github_client = Octokit::Client.new(access_token: github_token, auto_paginate: true)

        raise "invalid params in #{self.class.name}" if response.nil? || request.nil? || redis.nil?

        # https://developer.github.com/v3/activity/events/types/#issuecommentevent
        self.payload = JSON.parse(request.body.read)
        self.commenter = redis.get("alias:#{payload["sender"]["login"]}") || payload["sender"]["login"]
        self.issue_owner = redis.get("alias:#{payload["issue"]["user"]["login"]}") || payload["issue"]["user"]["login"]
        self.issue_title = payload["issue"]["title"]
        self.issue_html_url = payload["issue"]["html_url"]
        self.issue_body = payload["comment"]["body"]
      end

      def message
        self.status = repo_status(payload["repository"]["full_name"], payload["issue"])
        if !status[:last_comment].empty?
          if status[:list].include? Lita::GithubPrList::Status::PASS_DEV_EMOJI
            pass_dev?
          elsif status[:list].include? Lita::GithubPrList::Status::PASS_DESIGN_EMOJI
            pass_design?
          elsif status[:list].include? Lita::GithubPrList::Status::REVIEW_EMOJI
            "@#{commenter} is currently reviewing: #{issue_title}. #{issue_html_url}"
          elsif status[:list].include? Lita::GithubPrList::Status::FAIL_EMOJI
            "@#{issue_owner} your pull request: #{issue_title} has failed. #{issue_html_url}"
          elsif status[:list].include? Lita::GithubPrList::Status::FIXED_EMOJI
            "#{issue_title} has been fixed: #{issue_html_url}"
          end
        else
          nil
        end
      end

    private
      def pass_dev?
        if self.status[:list].include? Lita::GithubPrList::Status::PASS_DESIGN_EMOJI
          "@#{issue_owner} your pull request: #{issue_title} has passed. #{issue_html_url}"
        else
          resp = "@#{issue_owner} your pull request: #{issue_title} has passed DEV REVIEW. #{issue_html_url}"
          if self.status[:list].include?(Lita::GithubPrList::Status::DESIGN_REVIEW_REQUIRED) && !status[:list].include?(Lita::GithubPrList::Status::PASS_DESIGN_EMOJI)
            resp += " - You still require DESIGN REVIEW"
          end
          resp
        end
      end

      def pass_design?
        resp = "@#{issue_owner} your pull request: #{issue_title} has passed DESIGN. #{issue_html_url}"
        if self.status[:list].include?(Lita::GithubPrList::Status::DEV_REVIEW_REQUIRED) && !status[:list].match(Lita::GithubPrList::Status::PASS_DEV_EMOJI)
          resp += " - You still require DEV REVIEW"
        end
        resp
      end

      def repo_status(repo_full_name, issue)
        status_object = Lita::GithubPrList::Status.new(comment: ":new: " + issue["body"])
        status = status_object.comment_status
        comments(repo_full_name, issue["number"]).each do |c|
          status = status_object.update(c.body)
        end
        status
      end

      def comments(repo_full_name, issue_number, options = nil)
        github_options = options || { direction: 'asc', sort: 'created' }
        github_client.issue_comments(repo_full_name, issue_number, github_options)
      end
    end
  end
end
