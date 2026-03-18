# frozen_string_literal: true

module PlotWriter
  module Tools
    class Base
      MAX_SEARCH_RESULTS = 20

      attr_reader :user, :plot

      def initialize(user:, plot:)
        @user = user
        @plot = plot
      end

      def self.schema
        raise NotImplementedError, "#{self} must implement .schema"
      end

      def self.description
        raise NotImplementedError, "#{self} must implement .description"
      end

      # MCP用: すべてのMCPツールを返す
      def self.all
        [
          CrudSceneTool,
          CrudElementTool,
          SearchElementsTool
        ]
      end

      private

      def policy
        @policy ||= PlotPolicy.new(user, plot)
      end

      def manageable? = policy.own?

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

      def halt(message)
        json(status: "ok", message:)
      end
    end
  end
end
