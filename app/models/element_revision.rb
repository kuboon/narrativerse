class ElementRevision < ApplicationRecord
  belongs_to :element
  belongs_to :user
  has_many :plot_elements, dependent: :restrict_with_error

  validates :summary, length: { maximum: 100 }, allow_nil: true
  validates :text, length: { maximum: 1000 }, allow_nil: true
  validates :revision, presence: true, numericality: { only_integer: true, greater_than: 0 }
end
