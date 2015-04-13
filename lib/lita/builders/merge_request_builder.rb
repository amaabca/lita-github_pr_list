module Builders
  class MergeRequestBuilder
    attr_accessor :merge_request_data

    def initialize(args = {})
      self.merge_request_data = args.fetch(:merge_request_data, [])
    end

    def all
      merge_request_data.map do |m|
        OpenStruct.new(id: m["id"], state: m["state"])
      end
    end

    def closed
      all.select { |m| m.state.downcase != 'opened' }
    end
  end
end
