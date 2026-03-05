class PlotStory
  def initialize(plot)
    @plot = plot.is_a?(Plot) ? plot : Plot.find(plot)
  end

  def links
    return @links if @links

    plot_ids = [ @plot.id ] + @plot.parent_plot_ids
    links = PlotSceneLink.where(plot_id: plot_ids).includes(:scene, plot: :user).strict_loading.to_a
    first_link = links.find { |l| l.scene_id == @plot.scene_id }
    raise "first link not found for plot #{@plot.id} and scene #{@plot.scene_id}" unless first_link
    ordered_links = [ first_link ]
    return ordered_links if links.size < 2
    while (next_links = links.select { |l| l.scene_id == ordered_links.last.next_scene_id })
      link = plot_ids.each do |plot_id|
        found = next_links.find do |link|
          next unless link.plot_id == plot_id
          next if ordered_links.any? { |l| l.scene_id == link.scene_id }
          true
        end
        break found if found
      end
      raise "link not found for plot #{plot_id} and scene #{ordered_links.last.next_scene_id}" unless link
      ordered_links << link
      break if link.next_scene_id.nil?
    end
    @links = ordered_links
  end

  def scene_ids
    links.map(&:scene_id)
  end

  def branches
    return @branches if @branches
    related_links = PlotSceneLink.where(scene_id: scene_ids).includes(:plot).strict_loading.to_a
    branches_by_scene_id = {}
    links.each do |link|
      branches = related_links.select do |x|
        next if x.plot_id == link.plot_id
        next if x.scene_id != link.scene_id
        true
      end
      branches_by_scene_id[link.scene_id] = branches
    end
    @branches = branches_by_scene_id
  end
end
