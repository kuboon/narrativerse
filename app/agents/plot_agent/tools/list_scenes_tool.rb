# frozen_string_literal: true

module PlotAgent
  module Tools
    class ListScenesTool < BaseTool
      description "現在のプロットのシーン一覧を返します。"

      def execute
        links = PlotStory.new(plot).links
        scenes = links.each_with_index.map do |link, index|
          {
            order: index + 1,
            link_id: link.id,
            scene_id: link.scene_id,
            text: link.scene.text,
            next_scene_id: link.next_scene_id
          }
        end

        json(status: "ok", plot_id: plot.id, scenes:)
      end
    end
  end
end
