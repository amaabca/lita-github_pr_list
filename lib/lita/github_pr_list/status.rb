module Lita
  module GithubPrList
    class Status
      attr_accessor :comment, :base, :dev, :design, :status

      DESIGN_REVIEW_REGEX = /:art:/
      DEV_REVIEW_REGEX = /:elephant:/
      PASS_DEV_REGEX = /:elephant: :elephant: :elephant:/
      PASS_DESIGN_REGEX = /:art: :art: :art:/
      REVIEW_REGEX = /:book:/
      FAIL_REGEX = /:poop:|:hankey:/
      FIXED_REGEX = /:wave:/
      NEW_REGEX = /:new:/

      DESIGN_REVIEW_REQUIRED = "(art)"
      DEV_REVIEW_REQUIRED = "(elephant)"
      PASS_DEV_EMOJI = "(elephant)(elephant)(elephant)"
      PASS_DESIGN_EMOJI = "(art)(art)(art)"
      REVIEW_EMOJI = "(book)"
      FAIL_EMOJI = "(poop)"
      FIXED_EMOJI = "(wave)"
      NEW_EMOJI = "(new)"

      def initialize(params = {})
        self.comment = params.fetch(:comment, nil)
        self.base = "(new)"
        self.status = {}
        self.status[:last_comment] = ""
        setup(comment)
        raise "invalid params in #{self.class.name}" if comment.nil?
      end

      def comment_status
        case base
          when REVIEW_REGEX, FAIL_REGEX
            status[:list] = base
          else
            status[:list] = "#{base}#{dev}#{design}"
        end
        status
      end

      def update(new_comment)
        self.status[:last_comment] = ""
        self.status[:last_comment] += parse_dev(new_comment) unless self.dev.nil?
        self.status[:last_comment] += parse_design(new_comment) unless self.design.nil?
        self.status[:last_comment] += parse_common(new_comment)
        self.comment = new_comment
        comment_status
      end

    private

      def parse_dev(comm)
        case comm
          when PASS_DEV_REGEX
            self.base = ""
            self.dev = PASS_DEV_EMOJI
          when DEV_REVIEW_REGEX, FAIL_REGEX, FIXED_REGEX
            self.dev = DEV_REVIEW_REQUIRED
          else
            ""
        end
      end

      def parse_design(comm)
        case comm
          when PASS_DESIGN_REGEX
            self.base = ""
            self.design = PASS_DESIGN_EMOJI
          when DESIGN_REVIEW_REGEX, FAIL_REGEX, FIXED_REGEX
            self.design = DESIGN_REVIEW_REQUIRED
          else
            ""
        end
      end

      def parse_common(comm)
        case comm
          when REVIEW_REGEX
            self.base = REVIEW_EMOJI
          when FAIL_REGEX
            self.base = FAIL_EMOJI
          when FIXED_REGEX
            self.base = FIXED_EMOJI
          when NEW_REGEX
            self.base = NEW_EMOJI
          else
            ""
        end
      end

      def setup(comm)
        self.design = DESIGN_REVIEW_REQUIRED if comm.match(DESIGN_REVIEW_REGEX)
        self.dev = DEV_REVIEW_REQUIRED if comm.match(DEV_REVIEW_REGEX)
        if !comm.match(DESIGN_REVIEW_REGEX) && !comm.match(DEV_REVIEW_REGEX)
          self.dev =  DEV_REVIEW_REQUIRED
          self.design = DESIGN_REVIEW_REQUIRED
        end
      end
    end
  end
end
