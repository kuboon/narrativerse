class Scene < ApplicationRecord
  belongs_to :user
  has_many :plot_scene_links, dependent: :destroy
  has_many :plots, dependent: :nullify

  validates :text, presence: true, length: { maximum: 1000 }
end
