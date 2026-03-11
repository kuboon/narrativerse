# frozen_string_literal: true

module PlotChatbot
  module Tools
    class AddSceneTool < BaseTool
      description "現在のプロットに新しいシーンを追加します。"
      param :text, desc: "シーン本文"

      def execute(text:)
        return deny_message unless manageable?

        scene = Scene.create!(user:, text:)

        last_link = plot.plot_scene_links.find_by(next_scene_id: nil)
        last_link&.update!(next_scene_id: scene.id)

        link = PlotSceneLink.create!(plot:, scene:, next_scene_id: nil)

        json(
          status: "ok",
          message: "シーンを追加しました。",
          link_id: link.id,
          scene_id: scene.id
        )
      end
    end
  end
end
