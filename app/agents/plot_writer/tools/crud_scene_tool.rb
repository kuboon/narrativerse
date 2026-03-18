# frozen_string_literal: true

module PlotWriter
  module Tools
    class CrudSceneTool < Base
      def self.description = "現在のプロットのシーンを追加・更新・削除します。"

      def self.schema
        {
          type: "object",
          properties: {
            scene_id: {
              type: "integer",
              description: "更新する scene ID"
            },
            text: {
              type: "string",
              minLength: 500,
              maxLength: 1000,
              description: "シーンの内容"
            },
            delete: {
              type: "boolean",
              description: "シーンを削除する場合は true"
            }
          }
        }
      end

      def execute(scene_id: nil, text: nil, delete: false)
        return deny_message unless manageable?

        unless scene_id
          scene_id = Scene.create!(user:, text:).id
        end
        link = find_link(scene_id:)
        return json(status: "error", message: "対象シーンが見つかりません。") unless link

        if delete
          link.scene.destroy!
          return json(status: "ok", message: "シーンを削除しました。")
        end

        link.scene.update!(text:)

        json(status: "ok", message: "シーンを更新しました。")
      end

      private

      def find_link(scene_id:)
        plot.plot_scene_links.find_by(scene_id:)
      end
    end
  end
end
