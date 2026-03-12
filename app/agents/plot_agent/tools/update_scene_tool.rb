# frozen_string_literal: true

module PlotAgent
  module Tools
    class UpdateSceneTool < BaseTool
      description "現在のプロットのシーン本文を更新します。"
      param :text, desc: "更新後の本文"
      param :link_id, type: :integer, required: false, desc: "更新する link ID"
      param :scene_id, type: :integer, required: false, desc: "更新する scene ID"

      def execute(text:, link_id: nil, scene_id: nil)
        return deny_message unless manageable?

        link = find_link(link_id:, scene_id:)
        return json(status: "error", message: "対象シーンが見つかりません。") unless link

        link.scene.update!(text:)

        json(status: "ok", message: "シーンを更新しました。")
      end

      private

      def find_link(link_id:, scene_id:)
        return plot.plot_scene_links.find_by(id: link_id) if link_id.present?
        return plot.plot_scene_links.find_by(scene_id:) if scene_id.present?

        nil
      end
    end
  end
end
