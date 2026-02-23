class PlotForker
  def initialize(plot:, link:, user:)
    @plot = plot
    @link = link
    @user = user
  end

  def call
    raise ArgumentError, "invalid link" unless @link.plot_id == @plot.id

    navigation = PlotNavigation.new(@plot)
    parents = navigation.plot_chain

    if parents.any? { |parent| parent.user_id == @user.id }
      raise ArgumentError, "Cannot fork from your own plot lineage"
    end

    new_plot = Plot.create!(
      user: @user,
      title: "Fork of #{@plot.title}",
      summary: @plot.summary,
      scene_id: @link.scene_id
    )
    PlotParentLink.create!(child_plot: new_plot, parent_plot: @plot)
    new_link = PlotSceneLink.create!(plot: new_plot, scene: @link.scene, next_scene: nil)

    @plot.plot_elements.each do |pe|
      PlotElement.create!(
        plot: new_plot,
        element: pe.element,
        element_revision: pe.element_revision,
        summary: pe.summary
      )
    end

    { plot: new_plot, link: new_link }
  end
end
