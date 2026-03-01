class PlotStory
  def initialize(plot)
    @plot = plot.is_a?(Plot) ? plot : Plot.find(plot)
  end

  def call
    story_links = build_story_links

    {
      plot: @plot,
      story_links: story_links,
      branches_by_scene_id: build_branches_by_scene_id(story_links)
    }
  end

  private

  def build_story_links
    plots = [ @plot ] + @plot.parent_plots.to_a
    links = PlotSceneLink.where(plot_id: plots.map(&:id)).includes(:scene, plot: :user).strict_loading.to_a
    first_link = links.find { |l| l.scene_id == @plot.scene_id }
    ordered_links = [ first_link ]
    return ordered_links if links.size < 2
    while (next_links = links.select { |l| l.scene_id == ordered_links.last.next_scene_id })
      link = plots.each do |plot|
        found = next_links.find do |link|
          next unless link.plot_id == plot.id
          next if ordered_links.any? { |l| l.scene_id == link.scene_id }
          true
        end
        break found if found
      end
      raise "link not found for plot #{plot.id} and scene #{ordered_links.last.next_scene_id}" unless link
      ordered_links << link
      break if link.next_scene_id.nil?
    end
    ordered_links
  end

  def build_branches_by_scene_id(story_links)
    scene_ids = story_links.map(&:scene_id)
    links = PlotSceneLink.where(scene_id: scene_ids).includes(:plot).strict_loading.to_a
    branches_by_scene_id = {}
    links.each do |link|
      next if story_links.any? { |l| l.id == link.id }
      branches_by_scene_id[link.scene_id] ||= []
      branches_by_scene_id[link.scene_id] << link
    end
    branches_by_scene_id
  end
end
