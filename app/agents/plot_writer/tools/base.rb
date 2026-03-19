# frozen_string_literal: true

module PlotWriter
  module Tools
    class Base
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

      private

      def plot_policy
        @plot_policy ||= PlotPolicy.new(user, plot)
      end

      def own_plot? = plot_policy.own?

      def json(payload) = JSON.generate(payload)

      def success_response(message) = json(status: "ok", message:)
      def error_response(message) = json(status: "error", message:)

      def deny_message = error_response("このプロットを編集する権限がありません。")
    end
  end
end
