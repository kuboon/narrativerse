# frozen_string_literal: true

module PlotWriter
  module McpTools
    class SearchElementsTool < BaseTool
      description "プロット外の要素を検索します。"
      input_schema(
        properties: {
          query: { type: "string", description: "検索キーワード" },
          element_type: { type: "string", description: "Character / Item / Field" },
          limit: { type: "integer", description: "件数上限(最大20)" }
        }
      )

      wraps PlotWriter::Tools::SearchElementsTool

      class << self
        def call(query: nil, element_type: nil, limit: 10, server_context:)
          call_wrapped(arguments: { query:, element_type:, limit: }, server_context:)
        end
      end
    end
  end
end
