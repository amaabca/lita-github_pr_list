module Lita
  module GithubPrList
    class AliasUser
      attr_accessor :response, :redis

      def initialize(params)
        self.response = params.fetch(:response, nil)
        self.redis = params.fetch(:redis, nil)
        raise 'invalid params' if response.nil? || redis.nil?
      end

      def create_alias
        github_username, hipchat_username = response.matches.first[0], response.matches.first[1]
        redis.set("alias:#{github_username}", hipchat_username)
        response.reply "Mapped #{github_username} to #{hipchat_username}"
      end
    end
  end
end