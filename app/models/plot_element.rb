class PlotElement < ApplicationRecord
  belongs_to :plot
  belongs_to :element_revision
  has_one :element, through: :element_revision

  validates :summary, length: { maximum: 200 }, allow_nil: true
  validates :secrets, length: { maximum: 200 }, allow_nil: true

  broadcasts_to :plot

  def new_revision!(appearance:, description:)
    lock do
      revision = element_revision.element.new_revision!(user: element_revision.user, appearance:, description:)
      update!(element_revision: revision)
    end
  end
  def update_to_latest!(latest_revision: element_revision.element.latest_revision)
    return if element_revision_id == latest_revision.id

    update!(element_revision: latest_revision)
  end
end
