class User < ApplicationRecord
  has_many :plots, dependent: :destroy do
    def latest
      order(created_at: :desc, id: :desc).first
    end
  end
  has_many :elements, dependent: :destroy
  has_many :element_revisions, dependent: :destroy
  has_many :scenes, dependent: :destroy
  has_many :chats, dependent: :destroy
  has_one :chat, -> { order(created_at: :desc) }

  validates :name, presence: true
  validates :bio, length: { maximum: 200 }, allow_nil: true
end
