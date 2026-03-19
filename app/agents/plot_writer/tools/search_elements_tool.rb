# frozen_string_literal: true

module PlotWriter
  module Tools
    class SearchElementsTool < Base
      MAX_SEARCH_RESULTS = 20
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
              enum: Element::ELEMENT_TYPES
            }
          }
        }
      end

      def execute(query: nil, element_type: nil)
        scope = Element.order(created_at: :desc)
                       .where.not(id: plot.plot_elements.select(:element_id))

        if element_type.present? && Element::ELEMENT_TYPES.include?(element_type)
          scope = scope.where(element_type:)
        end

        scope
        .matching_query(query)
        .limit(MAX_SEARCH_RESULTS)
        .includes(:latest_revision)
        .map { _1.json_to(user:) }
      end
    end
  end
end
