# frozen_string_literal: true

module PlotWriter
  module Tools
    class CrudElementTool < Base
      def self.description = "現在のプロットへ要素を追加します。"

      def self.schema
        {
          type: "object",
          properties: {
            element_id: {
              type: "integer",
              description: "追加する要素 ID"
            },
            summary: {
              type: "string",
              description: "プロット内の役割"
            },
            secrets: {
              type: "string",
              description: "秘密の設定"
            }
          }
        }
      end

      def execute(element_id:, summary: nil, secrets: nil)
        return deny_message unless manageable?

        if plot.plot_elements.exists?(element_id:)
          return json(status: "error", message: "その要素は既に追加済みです。")
        end

        element = element_id ? Element.find_by(id: element_id) : Element.new

        revision = element.latest_revision
        return json(status: "error", message: "要素にリビジョンがありません。") unless revision

        plot_element = plot.plot_elements.create!(
          element:,
          element_revision: revision,
          summary:,
          secrets:
        )

        halt "要素を追加しました: #{plot_element.id}"
      end
    end
  end
end
