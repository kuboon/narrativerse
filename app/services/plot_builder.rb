class PlotBuilder
  def initialize(plot_id, link_id)
    @plot_id = plot_id.to_i
    @link_id = link_id
  end

  def call
    link = PlotSceneLink.find(@link_id)
    return empty_payload unless link.plot_id == @plot_id

    navigation = PlotNavigation.new(@plot_id)

    current_scene = link.scene
    next_scene = link.next_scene
    next_link = navigation.next_link_for(link.next_scene_id)
    prev_link = navigation.previous_link_for(link.scene_id)
    branches = branch_options(link.scene_id)

    {
      plot: link.plot,
      link: link,
      scene: current_scene,
      next_scene: next_scene,
      previous_scene: prev_link&.scene,
      previous_link: prev_link,
      next_link: next_link,
      branches: branches
    }
  end

  private

  def empty_payload
    {
      plot: nil,
      link: nil,
      scene: nil,
      next_scene: nil,
      previous_scene: nil,
      previous_link: nil,
      next_link: nil,
      branches: []
    }
  end

  def branch_options(scene_id)
    PlotSceneLink
      .where(scene_id: scene_id)
      .where.not(plot_id: @plot_id)
      .includes(plot: [:user, :plot_scene_links])
  end
end
