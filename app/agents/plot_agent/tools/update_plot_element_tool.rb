# frozen_string_literal: true

module PlotAgent
  module Tools
    class UpdatePlotElementTool < BaseTool
      description "現在のプロット内の要素設定を更新します。"
      param :plot_element_id, type: :integer, desc: "更新対象の plot_element ID"
      param :summary, required: false, desc: "プロット内の役割"
      param :secrets, required: false, desc: "秘密の設定"

      def execute(plot_element_id:, summary: nil, secrets: nil)
        return deny_message unless manageable?

        plot_element = plot.plot_elements.find_by(id: plot_element_id)
        return json(status: "error", message: "対象要素が見つかりません。") unless plot_element

        attrs = {}
        attrs[:summary] = summary unless summary.nil?
        attrs[:secrets] = secrets unless secrets.nil?

        if attrs.empty?
          return json(status: "error", message: "更新内容が指定されていません。")
        end

        plot_element.update!(attrs)

        json(status: "ok", message: "要素を更新しました。")
      end
    end
  end
end
