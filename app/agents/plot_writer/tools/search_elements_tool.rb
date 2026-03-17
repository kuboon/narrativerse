# frozen_string_literal: true

module PlotWriter
  module Tools
    class SearchElementsTool < BaseTool
      description "プロット外の要素を検索します。"
      param :query, required: false, desc: "検索キーワード"
      param :element_type, required: false, desc: "Character / Item / Field"
      param :limit, type: :integer, required: false, desc: "件数上限(最大20)"

      def execute(query: nil, element_type: nil, limit: 10)
        scope = Element.order(created_at: :desc)
                       .where.not(id: plot.plot_elements.select(:element_id))

        if element_type.present? && Element::ELEMENT_TYPES.include?(element_type)
          scope = scope.where(element_type:)
        end

        scope = scope.matching_query(query)

        elements = scope.limit(normalized_limit(limit))
                        .includes(:element_revisions)
                        .map do |element|
          {
            id: element.id,
            name: element.name,
            element_type: element.element_type,
            latest_summary: element.latest_revision&.summary
          }
        end

        json(status: "ok", elements:)
      end
    end
  end
end
