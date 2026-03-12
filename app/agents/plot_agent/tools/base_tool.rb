# frozen_string_literal: true

module PlotAgent
  module Tools
    class BaseTool < RubyLLM::Tool
      MAX_SEARCH_RESULTS = 20

      attr_reader :user, :plot

      def initialize(user:, plot:)
        @user = user
        @plot = plot
        super()
      end

      def name
        super.sub("--tools--", "--")
      end

      private

      def manageable?
        plot.user_id == user.id
      end

      def deny_message
        json(status: "error", message: "このプロットを編集する権限がありません。")
      end

      def json(payload)
        JSON.generate(payload)
      end

      def normalized_limit(limit, default: 10)
        value = limit.to_i
        value = default if value <= 0
        [ value, MAX_SEARCH_RESULTS ].min
      end
    end
  end
end
