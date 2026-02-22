class PlotSceneLink < ApplicationRecord
  belongs_to :plot
  belongs_to :scene
  belongs_to :next_scene, class_name: "Scene", optional: true
end
