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
      end

      route(/pr list/i, :list_org_pr, command: true, help: {
        "pr list" => "List open pull requests for an organization."
      })

      route(/pr alias user (\w*) (\w*)/i, :alias_user, command: true, help: {
        "pr alias user <Github Username> <Hipchat Username>" => "Create an alias to match a Github username to a Hipchat Username."
      })

      http.post "/comment_hook", :comment_hook

      def list_org_pr(response)
        Lita::GithubPrList::PullRequest.new({ github_organization: Lita.config.handlers.github_pr_list.github_organization,
                                              github_token: Lita.config.handlers.github_pr_list.github_access_token,
                                              response: response, redis: redis }).list
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
    end

    Lita.register_handler(GithubPrList)
  end
end