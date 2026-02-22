class ElementRevisionManager
  def initialize(element:, user:, revision_params:)
    @element = element
    @user = user
    @revision_params = revision_params
  end

  def create_initial
    build_revision(1)
  end

  def create_next
    next_number = (@element.latest_revision&.revision || 0) + 1
    build_revision(next_number)
  end

  private

  def build_revision(number)
    revision = @element.element_revisions.build(@revision_params)
    revision.user = @user
    revision.revision = number
    revision.save
    revision
  end
end
