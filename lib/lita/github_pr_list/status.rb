module Lita
  module GithubPrList
    class Status
      attr_accessor :comment, :status
      attr_accessor :pass_regex, :review_regex, :fail_regex, :fixed_regex

      PASS_REGEX = Regexp.new("/:elephant: :elephant: :elephant:/")
      REVIEW_REGEX = Regexp.new("/:book:/")
      FAIL_REGEX = Regexp.new("/:poop:/")
      FIXED_REGEX = Regexp.new("/:wave:/")

      PASS_EMOJI = "(elephant)(elephant)(elephant)"
      REVIEW_EMOJI = "(book)"
      FAIL_EMOJI = "(poop)"
      FIXED_EMOJI = "(wave)"

      def initialize(params)
        self.comment = params.fetch(:comment, nil)
        self.status = params.fetch(:status, {})

        raise 'invalid params' if comment.nil?

        self.pass_regex = /:elephant: :elephant: :elephant:/
        self.review_regex = /:book:/
        self.fail_regex = /:poop:/
        self.fixed_regex = /:wave:/
      end

      def comment_status
        case self.comment
          when pass_regex
            status[:emoji] = PASS_EMOJI
            status[:status] = "Passed"
          when review_regex
            status[:emoji] = REVIEW_EMOJI
            status[:status] = "In Review"
          when fail_regex
            status[:emoji] = FAIL_EMOJI
            status[:status] = "Failed"
          when fixed_regex
            status[:emoji] = FIXED_EMOJI
            status[:status] = "Fixed"
        end

        status
      end
    end
  end
end