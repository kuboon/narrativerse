module PlotWriter
  class McpServer < MCP::Server
    def initialize(user_id:, plot_id:)
      super(
        name: "narrativerse_plot_writer",
        title: "Narrativerse Plot Writer",
        version: "1.0.0",
        instructions: "Narrativerse のプロット編集を行うための MCP サーバーです。",
        tools: Tools::Mcp::Base.all,
        prompts: [ LatestPlotPrompt ],
        server_context: { user:, plot: }
      )
    end
  end
  class LatestPlotPrompt < MCP::Prompt
    prompt_name "latest_plot"
    description "認証ユーザーの最新プロット情報を返します。"

    def self.template(_, server_context: { user:, plot: })
      return error_result("プロットがまだありません。") unless plot

      erb_path = RubyLLM::Agent.send(:prompt_path_for, "instructions")
      text = ERB.new(File.read(erb_path)).result_with_hash(plot:)

      MCP::Prompt::Result.new(
        description: "最新プロット",
        messages: [
          MCP::Prompt::Message.new(
            role: "user",
            content: MCP::Content::Text.new(text)
          )
        ]
      )
    end

    private

    def self.error_result(message)
      MCP::Prompt::Result.new(
        description: "エラー",
        messages: [
          MCP::Prompt::Message.new(
            role: "user",
            content: MCP::Content::Text.new(message)
          )
        ]
      )
    end
  end
end
