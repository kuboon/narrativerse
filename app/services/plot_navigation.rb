class PlotNavigation
  def initialize(plot)
    @plot = plot.is_a?(Plot) ? plot : Plot.find(plot)
  end

  def plot_chain
    chain = [@plot]
    queue = @plot.parent_plots.to_a

    until queue.empty?
      current = queue.shift
      next if chain.any? { |existing| existing.id == current.id }

      chain << current
      queue.concat(current.parent_plots)
    end

    chain
  end

  def previous_link_for(scene_id)
    plot_chain.each do |plot|
      previous_link = PlotSceneLink.find_by(plot_id: plot.id, next_scene_id: scene_id)
      return previous_link if previous_link
    end
    nil
  end

  def next_link_for(scene_id)
    return nil unless scene_id

    plot_chain.each do |plot|
      next_link = PlotSceneLink.find_by(plot_id: plot.id, scene_id: scene_id)
      return next_link if next_link
    end
    nil
  end

  def previous_link_in_plot_for(scene_id)
    PlotSceneLink.find_by(plot_id: @plot.id, next_scene_id: scene_id)
  end

  def link_chain_to(scene_id)
    chain = []
    current_scene_id = scene_id
    seen_scene_ids = {}

    loop do
      previous_link = previous_link_for(current_scene_id)
      break unless previous_link
      break if seen_scene_ids[previous_link.scene_id]

      chain << previous_link
      seen_scene_ids[previous_link.scene_id] = true
      current_scene_id = previous_link.scene_id
    end

    chain.reverse
  end

  def link_chain_in_plot_to(scene_id)
    chain = []
    current_scene_id = scene_id
    seen_scene_ids = {}

    loop do
      previous_link = previous_link_in_plot_for(current_scene_id)
      break unless previous_link
      break if seen_scene_ids[previous_link.scene_id]

      chain << previous_link
      seen_scene_ids[previous_link.scene_id] = true
      current_scene_id = previous_link.scene_id
    end

    chain.reverse
  end
end
