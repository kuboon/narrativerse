class PlotSceneLink < ApplicationRecord
  belongs_to :plot
  belongs_to :scene
  belongs_to :next_scene, class_name: "Scene", optional: true

  after_create_commit -> {
    broadcast_remove_to plot, target: "story-flow-empty"
    broadcast_append_to plot, target: "story-flow", partial: "scenes/panel", locals: { link: self, highlight: true }
  }
  after_update_commit -> { broadcast_replace_to plot, target: self, partial: "scenes/panel", locals: { link: self, highlight: true } }
  after_destroy_commit -> { broadcast_remove_to plot, target: self }
end
