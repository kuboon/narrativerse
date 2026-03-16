# frozen_string_literal: true

module PlotWriter
  module Tools
    class AddPlotElementTool < BaseTool
      description "現在のプロットへ要素を追加します。"
      param :element_id, type: :integer, desc: "追加する要素 ID"
      param :summary, required: false, desc: "プロット内の役割"
      param :secrets, required: false, desc: "秘密の設定"

      def execute(element_id:, summary: nil, secrets: nil)
        return deny_message unless manageable?

        if plot.plot_elements.exists?(element_id:)
          return json(status: "error", message: "その要素は既に追加済みです。")
        end

        element = Element.find_by(id: element_id)
        return json(status: "error", message: "要素が見つかりません。") unless element

        revision = element.latest_revision
        return json(status: "error", message: "要素にリビジョンがありません。") unless revision

        plot_element = plot.plot_elements.create!(
          element:,
          element_revision: revision,
          summary:,
          secrets:
        )

        json(
          status: "ok",
          message: "要素を追加しました。",
          plot_element_id: plot_element.id
        )
      end
    end
  end
end
