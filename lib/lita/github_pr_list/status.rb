require 'pry'
module Lita
  module GithubPrList
    class Status
      attr_accessor :comment, :status,
                    :pass_regex, :review_regex, :fail_regex, :fixed_regex,
                    :base, :dev, :design

      DESIGN_REVIEW_REGEX = /:art:/
      DEV_REVIEW_REGEX = /:elephant:/
      PASS_REGEX = /:elephant: :elephant: :elephant:/
      PASS_DESIGN_REGEX = /:art: :art: :art:/
      REVIEW_REGEX = /:book:/
      FAIL_REGEX = /:poop:|:hankey:/
      FIXED_REGEX = /:wave:/
      NEW_REGEX = /:new:/

      DESIGN_REVIEW_REQUIRED = "(art)"
      DEV_REVIEW_REQUIRED = "(elephant)"
      PASS_EMOJI = "(elephant)(elephant)(elephant)"
      PASS_DESIGN_EMOJI = "(art)(art)(art)"
      REVIEW_EMOJI = "(book)"
      FAIL_EMOJI = "(poop)"
      FIXED_EMOJI = "(wave)"
      NEW_EMOJI = "(new)"

      def initialize(params = {})
        self.comment = params.fetch(:comment, nil)
        self.status = {}
        self.base = "(new)"
        setup(comment)
        raise "invalid params in #{self.class.name}" if comment.nil?
      end

      def comment_status
        display_comments
      end

      def update(new_comment)
        parse_dev(new_comment)
        parse_design(new_comment)
        parse_common(new_comment)
        self.comment = new_comment
        comment_status
      end

    private

      def display_comments
        case base
          when REVIEW_REGEX, FAIL_REGEX
            status[:emoji] = base
          else
            status[:emoji] = "#{base} #{dev} #{design}"
        end
        status
      end

      def parse_dev(comm)
        if self.dev.present?
          case comm
            when PASS_REGEX
              self.base = ""
              self.dev = PASS_EMOJI
            when DEV_REVIEW_REGEX, FAIL_REGEX, FIXED_REGEX
              self.dev = DEV_REVIEW_REQUIRED
          end
        end
      end

      def parse_design(comm)
        if self.design.present?
          case comm
            when PASS_DESIGN_REGEX
              self.base = ""
              self.design = PASS_DESIGN_EMOJI
            when DESIGN_REVIEW_REGEX, FAIL_REGEX, FIXED_REGEX
              self.design = DESIGN_REVIEW_REQUIRED
          end
        end
      end

      def parse_common(comm)
        case comm
          when REVIEW_REGEX
            self.base = REVIEW_EMOJI
            status[:status] = "In Review"
          when FAIL_REGEX
            self.base = FAIL_EMOJI
            status[:status] = "Failed"
          when FIXED_REGEX
            self.base = FIXED_EMOJI
            status[:status] = "Fixed"
          when NEW_REGEX
            self.base = NEW_EMOJI
            status[:status] = "New"
        end
      end

      def setup(comm)
        self.design = DESIGN_REVIEW_REQUIRED
        self.dev = DEV_REVIEW_REQUIRED
        if comm.match(DESIGN_REVIEW_REGEX) && !comm.match(DEV_REVIEW_REGEX)
          self.dev = ""
        end
        if comm.match(DEV_REVIEW_REGEX) && !comm.match(DESIGN_REVIEW_REGEX)
          self.design = ""
        end
      end
    end
  end
end
