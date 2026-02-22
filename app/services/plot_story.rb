class PlotStory
  def initialize(plot, focus_link_id: nil)
    @plot = plot.is_a?(Plot) ? plot : Plot.find(plot)
    @focus_link_id = focus_link_id&.to_i
    @navigation = PlotNavigation.new(@plot)
  end

  def call
    story_links = build_story_links
    focus_link = resolve_focus_link(story_links)

    {
      plot: @plot,
      story_links: story_links,
      focus_link: focus_link,
      branches: branches_for(focus_link)
    }
  end

  private

  def build_story_links
    links = []
    seen_scene_ids = {}
    current_scene_id = earliest_scene_id(@plot.scene_id)

    while current_scene_id && !seen_scene_ids[current_scene_id]
      link = @navigation.next_link_for(current_scene_id)
      break unless link

      links << link
      seen_scene_ids[current_scene_id] = true
      current_scene_id = link.next_scene_id
    end

    links
  end

  def earliest_scene_id(scene_id)
    current_scene_id = scene_id
    seen_scene_ids = {}

    loop do
      previous_link = @navigation.previous_link_for(current_scene_id)
      break unless previous_link
      break if seen_scene_ids[previous_link.scene_id]

      seen_scene_ids[previous_link.scene_id] = true
      current_scene_id = previous_link.scene_id
    end

    current_scene_id
  end

  def resolve_focus_link(story_links)
    if @focus_link_id
      story_links.find { |link| link.id == @focus_link_id }
    else
      @navigation.next_link_for(@plot.scene_id)
    end
  end

  def branches_for(link)
    return [] unless link

    PlotSceneLink
      .where(scene_id: link.scene_id)
      .where.not(plot_id: @plot.id)
      .includes(plot: :user)
  end
end
