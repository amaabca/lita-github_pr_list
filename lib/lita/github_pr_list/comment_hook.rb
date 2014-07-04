module Lita
  module GithubPrList
    class CommentHook
      attr_accessor :request, :response, :payload, :commenter, :issue_owner, :issue_title, :issue_body, :status,
                    :issue_html_url, :redis

      def initialize(params)
        self.response = params.fetch(:response, nil)
        self.request = params.fetch(:request, nil)
        self.redis = params.fetch(:redis, nil)

        raise 'invalid params' if response.nil? || request.nil? || redis.nil?

        # https://developer.github.com/v3/activity/events/types/#issuecommentevent
        self.payload = JSON.parse(request.body.read)
        self.commenter = redis.get("alias:#{payload["sender"]["login"]}") || payload["sender"]["login"]
        self.issue_owner = redis.get("alias:#{payload["issue"]["user"]["login"]}") || payload["issue"]["user"]["login"]
        self.issue_title = payload["issue"]["title"]
        self.issue_html_url = payload["issue"]["html_url"]
        self.issue_body = payload["comment"]["body"]
      end

      def message
        status = Status.new({comment: issue_body}).comment_status

        if !status.empty?
          if status[:emoji] == Lita::GithubPrList::Status::PASS_EMOJI
            "@#{issue_owner} your pull request: #{issue_title} has passed. #{issue_html_url}"
          elsif status[:emoji] == Lita::GithubPrList::Status::REVIEW_EMOJI
            "@#{commenter} is currently reviewing: #{issue_title}. #{issue_html_url}"
          elsif status[:emoji] == Lita::GithubPrList::Status::FAIL_EMOJI
            "@#{issue_owner} your pull request: #{issue_title} has failed. #{issue_html_url}"
          elsif status[:emoji] == Lita::GithubPrList::Status::FIXED_EMOJI
            "#{issue_title} has been fixed: #{issue_html_url}"
          end
        else
          nil
        end
      end
    end
  end
end