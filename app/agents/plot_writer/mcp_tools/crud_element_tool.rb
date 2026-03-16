# frozen_string_literal: true

module PlotWriter
  module McpTools
    class CrudElementTool < BaseTool
      description "現在のプロットへ要素を追加します。"
      input_schema(
        properties: {
          element_id: { type: "integer", description: "追加する要素 ID" },
          summary: { type: "string", description: "プロット内の役割" },
          secrets: { type: "string", description: "秘密の設定" }
        }
      )

      wraps PlotWriter::Tools::CrudElementTool

      class << self
        def call(element_id: nil, summary: nil, secrets: nil, server_context:)
          call_wrapped(arguments: { element_id:, summary:, secrets: }, server_context:)
        end
      end
    end
  end
end
