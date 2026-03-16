# frozen_string_literal: true

module PlotWriter
  module McpPrompts
    class LatestPlotPrompt < MCP::Prompt
      prompt_name "latest_plot"
      description "認証ユーザーの最新プロット情報を返します。"

      class << self
        def template(args, server_context:)
          _ = args
          user_id = server_context&.dig(:user_id)
          user = User.find_by(id: user_id)

          return error_result("ユーザーが見つかりません。") unless user

          plot = user.plots.latest
          return error_result("プロットがまだありません。") unless plot

          data = {
            id: plot.id,
            title: plot.title,
            summary: plot.summary,
            created_at: plot.created_at&.iso8601,
            updated_at: plot.updated_at&.iso8601
          }

          MCP::Prompt::Result.new(
            description: "最新プロット",
            messages: [
              MCP::Prompt::Message.new(
                role: "user",
                content: MCP::Content::Text.new(JSON.generate(data))
              )
            ]
          )
        end

        private

        def error_result(message)
          MCP::Prompt::Result.new(
            description: "エラー",
            messages: [
              MCP::Prompt::Message.new(
                role: "assistant",
                content: MCP::Content::Text.new(message)
              )
            ]
          )
        end
      end
    end
  end
end
