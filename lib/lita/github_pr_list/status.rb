module Lita
  module GithubPrList
    class Status
      attr_accessor :comment, :status,
                    :pass_regex, :review_regex, :fail_regex, :fixed_regex

      PASS_REGEX = /:elephant: :elephant: :elephant:/
      PASS_DESIGN_REGEX = /:art: :art: :art:/
      REVIEW_REGEX = /:book:/
      FAIL_REGEX = /:poop:|:hankey:/
      FIXED_REGEX = /:wave:/

      PASS_EMOJI = "(elephant)(elephant)(elephant)"
      PASS_DESIGN_EMOJI = "(art)(art)(art)"
      REVIEW_EMOJI = "(book)"
      FAIL_EMOJI = "(poop)"
      FIXED_EMOJI = "(wave)"

      def initialize(params = {})
        self.comment = params.fetch(:comment, nil)
        self.status = params.fetch(:status, {})

        raise "invalid params in #{self.class.name}" if comment.nil?
      end

      def comment_status
        case self.comment
          when PASS_REGEX
            status[:emoji] = PASS_EMOJI
            status[:status] = "Passed"
          when PASS_DESIGN_REGEX
            status[:emoji] = PASS_DESIGN_EMOJI
            status[:status] = "Passed DESIGN"
          when REVIEW_REGEX
            status[:emoji] = REVIEW_EMOJI
            status[:status] = "In Review"
          when FAIL_REGEX
            status[:emoji] = FAIL_EMOJI
            status[:status] = "Failed"
          when FIXED_REGEX
            status[:emoji] = FIXED_EMOJI
            status[:status] = "Fixed"
        end

        status
      end
    end
  end
end
