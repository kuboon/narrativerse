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

  def self.build_revision(user:, element_type:, name:)
    element = new(user:, element_type:, name:)
    element.build_latest_revision(user:, revision: 1)
  end

  def json_to(user:)
    {
      id: id,
      element_type: element_type,
      name: name,
      own: user == self.user,
      appearance: latest_revision.appearance,
      description: latest_revision.description
    }
  end

  def new_revision!(user:, appearance:, description:)
    latest_revision.with_lock do
      if latest_revision.plot_elements.where.not(user: user).exists?
        element_revisions.create!(
          user:,
          revision: latest_revision.revision + 1,
          appearance:,
          description:
        )
      else
        latest_revision.update!(appearance:, description:)
      end
    end
  end
end
