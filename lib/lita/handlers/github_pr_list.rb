require "lita"
require "json"

module Lita
  module Handlers
    class GithubPrList < Handler
      def initialize(robot)
        super
      end

      def self.default_config(config)
        config.github_organization = nil
        config.github_access_token = nil
        config.comment_hook_url = nil
        config.comment_hook_event_type = nil
        config.pull_request_open_message_hook_url = nil
        config.pull_request_open_message_hook_event_type = nil
      end

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
      http.post "/merge_request_action", :merge_request_action
      http.post "/pull_request_open_message_hook", :pull_request_open_message_hook

      def list_org_pr(response)
        pull_requests = Lita::GithubPrList::PullRequest.new({ github_organization: github_organization,
                                                              github_token: github_access_token,
                                                              response: response }).list
        merge_requests = redis.keys("gitlab_mr*").map { |key| redis.get(key) }

        requests = pull_requests + merge_requests
        message = "I found #{requests.count} open pull requests for #{github_organization}\n"
        response.reply(message + requests.join("\n"))
      end

      def alias_user(response)
        Lita::GithubPrList::AliasUser.new({ response:response, redis: redis }).create_alias
      end

      def comment_hook(request, response)
        message = Lita::GithubPrList::CommentHook.new({ request: request, response: response, redis: redis, github_organization: github_organization, github_token: github_access_token}).message
        message_rooms(message, response)
      end

      def pull_request_open_message_hook(request, response)
        message = Lita::GithubPrList::PullRequestOpenMessageHook.new({ request: request, response: response, redis: redis }).message
        message_rooms(message, response)
      end

      def message_rooms(message, response)
        rooms = Lita.config.adapters.hipchat.rooms
        rooms ||= [:all]
        rooms.each do |room|
          target = Source.new(room: room)
          robot.send_message(target, message) unless message.nil?
        end

        response.body << "Nothing to see here..."
      end

      def add_pr_hooks(response)
        hook_info.each_pair do |key, val|
          Lita::GithubPrList::WebHook.new(github_organization: github_organization, github_token: github_access_token,
                                web_hook: val[:hook_url], response: response, event_type: val[:event_type]).add_hooks
        end
      end

      def remove_pr_hooks(response)
        hook_info.each_pair do |key, val|
          Lita::GithubPrList::WebHook.new(github_organization: github_organization, github_token: github_access_token,
                            web_hook: val[:hook_url], response: response, event_type: val[:event_type]).remove_hooks
        end
      end

      def merge_request_action(request, response)
        payload = JSON.parse(request.body.read)
        if payload["object_kind"] == "merge_request"
          attributes = payload["object_attributes"]
          Lita::GithubPrList::MergeRequest.new({ id: attributes["id"],
                                                 title: attributes["title"],
                                                 state: attributes["state"],
                                                 redis: redis }).handle
        end
      end

    private

      def github_organization
        Lita.config.handlers.github_pr_list.github_organization
      end

      def github_access_token
        Lita.config.handlers.github_pr_list.github_access_token
      end

      def hook_info
        { comment_hook: { hook_url: comment_hook_url, event_type: comment_hook_event_type },
          pull_request_open_message_hook: { hook_url: pull_request_open_message_hook_url, event_type: pull_request_open_message_hook_event_type } }
      end

      def comment_hook_url
        Lita.config.handlers.github_pr_list.comment_hook_url
      end

      def comment_hook_event_type
        Lita.config.handlers.github_pr_list.comment_hook_event_type
      end

      def pull_request_open_message_hook_url
        Lita.config.handlers.github_pr_list.pull_request_open_message_hook_url
      end

      def pull_request_open_message_hook_event_type
        Lita.config.handlers.github_pr_list.pull_request_open_message_hook_event_type
      end
    end
    Lita.register_handler(GithubPrList)

  end
end
