# frozen_string_literal: true

module PlotWriter
  module Tools
    class CrudSceneTool < BaseTool
      description "現在のプロットのシーン本文を更新します。"
      params do
        integer :scene_id, required: false, description: "更新する scene ID"
        string :text, min_length: 500, max_length: 1000, description: "シーンの内容"
        boolean :delete, required: false, description: "シーンを削除する場合は true"
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
