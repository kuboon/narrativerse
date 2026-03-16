class PlotEditor
  include Turbo::Broadcastable
  def model_name = "Plot"

  def initialize(plot:, user:)
    @plot = plot
    @user = user
  end

  def add_scene(text:)
    scene = Scene.create!(text:, user: @user)
    last_link = PlotSceneLink.find_by(plot_id: @plot.id, next_scene_id: nil)
    last_link.update!(next_scene_id: scene.id) if last_link
    @plot.update!(scene: scene) if @plot.scene_id.blank?
    new_link = PlotSceneLink.create!(plot: @plot, scene:, next_scene_id: nil)
    new_link.broadcast_append_to @plot, locals: { own: true }
    new_link
  end

  def fork(link:)
    raise ArgumentError, "invalid link" unless link.plot_id == @plot.id

    new_plot = Plot.create!(
      user: @user,
      title: "Fork of #{@plot.title}",
      summary: @plot.summary,
      scene_id: @plot.scene_id,
      parent_plot_ids: [ *@plot.parent_plot_ids, @plot.id ]
    )
    new_link = PlotSceneLink.create!(plot: new_plot, scene: link.scene, next_scene: nil)

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
