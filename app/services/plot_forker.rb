class PlotForker
  def initialize(plot:, link:, user:)
    @plot = plot
    @link = link
    @user = user
  end

  def call
    raise ArgumentError, "invalid link" unless @link.plot_id == @plot.id

    new_plot = Plot.create!(
      user: @user,
      title: "Fork of #{@plot.title}",
      summary: @plot.summary,
      scene_id: @link.scene_id
    )
    PlotParentLink.create!(child_plot: new_plot, parent_plot: @plot)
    new_link = PlotSceneLink.create!(plot: new_plot, scene: @link.scene, next_scene: nil)

    { plot: new_plot, link: new_link }
  end
end
