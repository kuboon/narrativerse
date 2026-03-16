# frozen_string_literal: true

module PlotWriter
  module Tools
    class ListPlotElementsTool < BaseTool
      description "現在のプロットに紐づく要素一覧を返します。"

      def execute
        elements = plot.plot_elements
                       .includes(:element, :element_revision)
                       .order(:id)
                       .map do |plot_element|
          {
            id: plot_element.id,
            element_id: plot_element.element_id,
            name: plot_element.element.name,
            element_type: plot_element.element.element_type,
            plot_role: plot_element.summary,
            secrets: plot_element.secrets,
            element_summary: plot_element.element_revision.summary
          }
        end

        json(status: "ok", plot_id: plot.id, elements:)
      end
    end
  end
end
