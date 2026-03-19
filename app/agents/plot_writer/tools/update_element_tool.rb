# frozen_string_literal: true

module PlotWriter
  module Tools
    class UpdateElementTool < Base
      def self.description = "現在のプロットの要素を追加、編集、削除"

      def self.schema
        {
          type: "object",
          properties: {
            plot_element_id: {
              type: "integer"
            },
            revision: {
              type: "object",
              properties: {
                appearance: {
                  type: "string",
                  description: "外見の説明",
                  required: true
                },
                description: {
                  type: "string",
                  description: "詳細な説明"
                }
              }
            },
            plot_element: {
              type: "object",
              properties: {
                summary: {
                  type: "string",
                  description: "プロット内での役割"
                },
                secrets: {
                  type: "string",
                  description: "プロット内での秘密の設定"
                }
              }
            }
          },
          required: [ "plot_element_id" ]
        }
      end

      def execute(plot_element_id:, revision: nil, plot_element: nil)
        return deny_message unless own_plot?

        plot_element = plot.plot_elements.find_by(id: plot_element_id)
        return error_response("プロット要素が見つかりません。") unless plot_element
        if revision.present?
          plot_element.new_revision!(user:, **revision.symbolize_keys)
        end
        if plot_element.present?
          plot_element.update!(plot_element)
        end

        element.save!
        success_response("要素を追加しました: #{element.id}")
      rescue => e
        error_response("要素の追加に失敗しました: #{e.message}")
      end
    end
  end
end
