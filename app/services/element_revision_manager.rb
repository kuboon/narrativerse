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
    if revision.save
      update_owned_plot_elements(revision)
      prune_unreferenced_revisions(revision.id)
    end
    revision
  end

  def update_owned_plot_elements(revision)
    PlotElement.joins(:plot)
               .where(element_id: @element.id, plots: { user_id: @user.id })
               .update_all(element_revision_id: revision.id, updated_at: Time.current)
  end

  def prune_unreferenced_revisions(current_revision_id)
    ElementRevision
      .where(element_id: @element.id)
      .where.not(id: current_revision_id)
      .left_joins(:plot_elements)
      .where(plot_elements: { id: nil })
      .delete_all
  end
end
