require "lita"
require "json"

module Lita
  module Handlers
    class GithubPrList < Handler
      def initialize(robot)
        super
      end

      config :github_organization
      config :github_access_token
      config :comment_hook_url
      config :comment_hook_event_type
      config :check_list_hook_url
      config :check_list_event_type
      config :pull_request_open_message_hook_url
      config :pull_request_open_message_hook_event_type
      config :gitlab_api_key

      route(/pr list/i, :list_org_pr, command: true,
            help: { "pr list" => "List open pull requests for an organization." }
      )

      route(/pr add hooks/i, :add_pr_hooks, command: true,
            help: { "pr add hooks" => "Add a pr web hook to every repo in your organization." }
      )

      route(/pr remove hooks/i, :remove_pr_hooks, command: true,
            help: { "pr remove hooks" => "Remove the pr web hook from every repo in your organization." }
      )

      route(/pr alias user (\w*) (\w*)/i, :alias_user, command: true,
            help: { "pr alias user <GithubUsername> <HipchatUsername>" => "Create an alias to match a Github "\
                    "username to a Hipchat Username." }
      )

      http.post "/comment_hook", :comment_hook
      http.post "/check_list", :check_list
      http.post "/merge_request_action", :merge_request_action
      http.post "/pull_request_open_message_hook", :pull_request_open_message_hook

      def list_org_pr(response)
        response.reply(pr_list_message)
      end

      def alias_user(response)
        Lita::GithubPrList::AliasUser.new({ response:response, redis: redis }).create_alias
      end

      def comment_hook(request, response)
        message = Lita::GithubPrList::CommentHook.new({ request: request, response: response, redis: redis }).message
        message_rooms(message, response)
      end

      def check_list(request, response)
        check_list_params = { request: request, response: response, redis: redis, github_token: github_access_token }
        Lita::GithubPrList::CheckList.new(check_list_params)
      end

      def pull_request_open_message_hook(request, response)
        message = Lita::GithubPrList::PullRequestOpenMessageHook.new({ request: request, response: response, redis: redis }).message
        message_rooms(message, response)
      end

      def message_rooms(message, response)
        rooms = Lita.config.adapter.rooms
        rooms ||= [:all]
        rooms.each do |room|
          target = Source.new(room: room)
          robot.send_message(target, message) unless message.nil?
        end

        response.body << "Nothing to see here..."
      end

      def add_pr_hooks(response)
        hook_info.each_pair do |key, val|
          Lita::GithubPrList::WebHook.new(
            github_organization: github_organization,
            github_token: github_access_token,
            web_hook: val[:hook_url],
            response: response,
            event_type: val[:event_type]
          ).add_hooks
        end
      end

      def remove_pr_hooks(response)
        hook_info.each_pair do |key, val|
          Lita::GithubPrList::WebHook.new(
            github_organization: github_organization,
            github_token: github_access_token,
            web_hook: val[:hook_url],
            response: response,
            event_type: val[:event_type]
          ).remove_hooks
        end
      end

      def merge_request_action(request, response)
        payload = JSON.parse(request.body.read)
        if payload["object_kind"] == "merge_request"
          attributes = payload["object_attributes"]
          Lita::GithubPrList::MergeRequest.new({
            id: attributes["id"],
            title: attributes["title"],
            state: attributes["state"],
            redis: redis
          }).handle
        end
      end

    private

      def handler
        Lita.config.handlers.github_pr_list
      end

      def github_organization
        handler.github_organization
      end

      def github_access_token
        handler.github_access_token
      end

      def hook_info
        {
          comment_hook: {
            hook_url: comment_hook_url,
            event_type: comment_hook_event_type
          },
          check_list_hook: {
            hook_url: check_list_hook_url,
            event_type: check_list_event_type
          },
          pull_request_open_message_hook: {
            hook_url: pull_request_open_message_hook_url,
            event_type: pull_request_open_message_hook_event_type
          }
        }
      end

      def comment_hook_url
        handler.comment_hook_url
      end

      def comment_hook_event_type
        handler.comment_hook_event_type
      end

      def pull_request_open_message_hook_url
        handler.pull_request_open_message_hook_url
      end

      def pull_request_open_message_hook_event_type
        handler.pull_request_open_message_hook_event_type
      end

      def check_list_hook_url
        handler.check_list_hook_url
      end

      def check_list_event_type
        handler.check_list_event_type
      end

      def include_gitlab?
        !handler.gitlab_api_key.nil?
      end

      def pull_requests
        Lita::GithubPrList::PullRequest.new({
          github_organization: github_organization,
          github_token: github_access_token
        }).list
      end

      def merge_requests
        Lita::GithubPrList::GitlabMergeRequests.new(redis: redis).rectify if include_gitlab?
        redis.keys("gitlab_mr*").map { |key| redis.get(key) }
      end

      def pr_list_message
        requests = pull_requests + merge_requests
        message = "I found #{requests.count} open pull requests for #{github_organization}\n"
        message + requests.join("\n")
      end
    end

    Lita.register_handler(GithubPrList)

  end
end
