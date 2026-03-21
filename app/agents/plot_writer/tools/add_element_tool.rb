# frozen_string_literal: true

module PlotWriter
  module Tools
    class AddElementTool < Base
      def self.description = "現在のプロットの要素を追加、編集、削除"

      def self.schema
        {
          type: "object",
          properties: {
            element: {
              oneOf: [
                {
                  type: "object",
                  properties: {
                    element_id: {
                      type: "integer",
                      description: "既存の要素をplotへ追加する場合"
                    }
                  },
                  required: [ "element_id" ]
                },
                {
                  type: "object",
                  properties: {
                    type: {
                      enum: Element::ELEMENT_TYPES
                    },
                    name: {
                      type: "string",
                      description: "要素の名前"
                    }
                  },
                  required: [ "type", "name" ]
                } ]
            },
            revision: {
              type: "object",
              properties: {
                appearance: {
                  type: "string",
                  description: "外見の説明"
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
          required: [ "element" ]
        }
      end

      def execute(element:, revision: nil, plot_element: nil)
        return deny_message unless own_plot?

        element_id = element["element_id"]
        if element_id.present?
          element_record = Element.find_by(id: element_id)
          return error_response("要素が見つかりません。") unless element_record
          pe = plot.plot_elements.joins(:element).find_by(elements: { id: element_record.id })
          pe ||= plot.plot_elements.build(element_revision: element_record.latest_revision)
        else
          element_revision = Element.build_revision(user:, **element.symbolize_keys)
          pe = plot.plot_elements.build(element_revision:)
        end
        if revision.present?
          pe.new_revision!(user:, **revision.symbolize_keys)
        end
        if plot_element.present?
          pe.attributes = plot_element
        end
        pe.save!

        success_response("要素を追加しました")
      rescue => e
        raise e if Rails.env.test?
        error_response("要素の追加に失敗しました: #{e.message}")
      end
    end
  end
end
