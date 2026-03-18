# frozen_string_literal: true

module PlotWriter
  module Tools
    class SearchElementsTool < Base
      def self.description = "プロット外の要素を検索します。"

      def self.schema
        {
          type: "object",
          properties: {
            query: {
              type: "string",
              description: "検索キーワード"
            },
            element_type: {
              type: "string",
              enum: Element::ELEMENT_TYPES,
              description: "Character / Item / Field"
            },
            limit: {
              type: "integer",
              description: "件数上限(最大20)"
            }
          }
        }
      end

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
