class Element < ApplicationRecord
  ELEMENT_TYPES = %w[Character Item Field].freeze

  scope :matching_query, ->(query) do
    if query.present?
      q = "%#{sanitize_sql_like(query)}%"
      left_joins(:element_revisions)
        .where(
          "elements.name LIKE :q OR element_revisions.summary LIKE :q OR element_revisions.text LIKE :q",
          q:
        )
        .distinct
    else
      all
    end
  end

  belongs_to :user
  has_many :element_revisions, dependent: :destroy
  has_one :latest_revision, -> { order(revision: :desc) }, class_name: "ElementRevision"
  has_many :plot_elements, dependent: :destroy

  validates :element_type, presence: true, inclusion: { in: ELEMENT_TYPES }
  validates :name, presence: true
  broadcasts
end
