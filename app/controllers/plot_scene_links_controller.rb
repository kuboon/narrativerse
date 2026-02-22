class PlotSceneLinksController < ApplicationController
  before_action :require_login, except: :show

  def show
    builder = PlotBuilder.new(params[:plot_id], params[:id])
    @payload = builder.call
    return render plain: "Not found", status: :not_found unless @payload[:plot]
  end

  def new
    @plot = Plot.find(params[:plot_id])
    return render plain: "Forbidden", status: :forbidden unless @plot.user == current_user

    @scene = Scene.new
  end

  def create
    @plot = Plot.find(params[:plot_id])
    return render plain: "Forbidden", status: :forbidden unless @plot.user == current_user

    @scene = Scene.new(scene_params)
    @scene.user = current_user

    if @scene.save
      last_link = PlotSceneLink.find_by(plot_id: @plot.id, next_scene_id: nil)
      last_link.update!(next_scene_id: @scene.id) if last_link
      new_link = PlotSceneLink.create!(plot: @plot, scene: @scene, next_scene_id: nil)
      redirect_to plot_plot_scene_link_path(@plot, new_link)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def fork
    source_plot = Plot.find(params[:plot_id])
    source_link = PlotSceneLink.find(params[:id])
    return render plain: "Not found", status: :not_found unless source_link.plot_id == source_plot.id
    return render plain: "Login required", status: :unauthorized unless current_user

    navigation = PlotNavigation.new(source_plot)
    parent_chain = navigation.link_chain_to(source_link.scene_id)

    new_plot = Plot.create!(
      user: current_user,
      title: "Fork of #{source_plot.title}",
      summary: source_plot.summary,
      scene_id: source_link.scene_id
    )
    PlotParentLink.create!(child_plot: new_plot, parent_plot: source_plot)

    created_links = parent_chain.map do |link|
      PlotSceneLink.create!(plot: new_plot, scene_id: link.scene_id, next_scene_id: link.next_scene_id)
    end

    new_link = PlotSceneLink.create!(plot: new_plot, scene: source_link.scene, next_scene: nil)
    if created_links.any?
      created_links.last.update!(next_scene_id: new_link.scene_id)
    end

    redirect_to plot_plot_scene_link_path(new_link.plot, new_link), notice: "Forked plot"
  end

  private

  def scene_params
    params.require(:scene).permit(:text)
  end
end
