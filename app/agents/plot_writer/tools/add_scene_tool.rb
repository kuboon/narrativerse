# frozen_string_literal: true

module PlotWriter
  module Tools
    class AddSceneTool < BaseTool
      description "現在のプロットに新しいシーンを追加します。"
      params do
        string :text, min_length: 500, max_length: 1000, description: "シーンの内容"
      end

      def execute(text:)
        return deny_message unless manageable?

        scene = Scene.create!(user:, text:)

        last_link = plot.plot_scene_links.find_by(next_scene_id: nil)
        last_link&.update!(next_scene_id: scene.id)

        PlotSceneLink.create!(plot:, scene:, next_scene_id: nil)

        halt "追加しました"
      end
    end
  end
end
