class Element < ApplicationRecord
  ELEMENT_TYPES = %w[Character Item Field].freeze

  belongs_to :user
  has_many :element_revisions, dependent: :destroy
  has_one :latest_revision, -> { order(revision: :desc) }, class_name: "ElementRevision"
  has_many :plot_elements, dependent: :destroy

  validates :element_type, presence: true, inclusion: { in: ELEMENT_TYPES }
  validates :name, presence: true
  broadcasts
end
