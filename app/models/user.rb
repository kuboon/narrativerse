class User < ApplicationRecord
  has_many :plots, dependent: :destroy
  has_many :elements, dependent: :destroy
  has_many :element_revisions, dependent: :destroy
  has_many :scenes, dependent: :destroy

  validates :name, presence: true
  validates :bio, length: { maximum: 200 }, allow_nil: true
end
