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
              description: "追加時は 省略可能。更新・削除時は必須"
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
        return deny_message unless own_plot?

        editor = PlotEditor.new(user:, plot:)

        unless scene_id
          editor.add_scene(text:)
          return json(status: "ok", message: "シーンを追加しました。")
        end

        story = plot.story
        link = story.links.find { it.scene_id == scene_id }
        return json(status: "error", message: "対象シーンが見つかりません。") unless link
        if delete
          link.scene.destroy!
          return json(status: "ok", message: "シーンを削除しました。")
        end

        editor.update_scene(link:, text:)

        json(status: "ok", message: "シーンを更新しました。")
      end
    end
  end
end
