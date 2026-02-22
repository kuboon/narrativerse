class PlotBuilder
  def initialize(plot_id, link_id)
    @plot_id = plot_id
    @link_id = link_id
  end

  def call
    link = PlotSceneLink.find(@link_id)
    current_scene = link.scene
    next_scene = link.next_scene
    prev_scene = previous_scene(link.scene_id)
    branches = branch_options(link.scene_id)

    {
      plot: link.plot,
      link: link,
      scene: current_scene,
      next_scene: next_scene,
      previous_scene: prev_scene,
      branches: branches
    }
  end

  private

  def plot_chain
    plot = Plot.find(@plot_id)
    chain = [plot]
    queue = plot.parent_plots.to_a

    until queue.empty?
      current = queue.shift
      next if chain.any? { |existing| existing.id == current.id }

      chain << current
      queue.concat(current.parent_plots)
    end

    chain
  end

  def previous_scene(scene_id)
    plot_chain.each do |plot|
      previous_link = PlotSceneLink.find_by(plot_id: plot.id, next_scene_id: scene_id)
      return previous_link.scene if previous_link
    end
    nil
  end

  def branch_options(scene_id)
    PlotSceneLink
      .where(scene_id: scene_id)
      .where.not(plot_id: @plot_id)
      .includes(:plot)
  end
end
