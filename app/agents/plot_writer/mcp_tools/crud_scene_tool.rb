# frozen_string_literal: true

module PlotWriter
  module McpTools
    class CrudSceneTool < BaseTool
      description "現在のプロットのシーンを追加・更新・削除します。"
      input_schema(
        properties: {
          scene_id: { type: "integer", description: "更新/削除対象の scene ID" },
          text: { type: "string", description: "シーン本文" },
          delete: { type: "boolean", description: "true の場合はシーン削除" }
        }
      )

      wraps PlotWriter::Tools::CrudSceneTool

      class << self
        def call(scene_id: nil, text: nil, delete: false, server_context:)
          call_wrapped(arguments: { scene_id:, text:, delete: }, server_context:)
        end
      end
    end
  end
end
