module Lita
  module GithubPrList
    class CheckList
      attr_accessor :request, :response, :payload, :redis

      def initialize(params = {})
        self.response = params.fetch(:response, nil)
        self.request = params.fetch(:request, nil)
        self.redis = params.fetch(:redis, nil)

        raise "invalid params in #{self.class.name}" if response.nil? || request.nil? || redis.nil?

        # https://developer.github.com/v3/activity/events/types/#issuecommentevent
        self.payload = JSON.parse(request.body.read)


      end


    end
  end
end