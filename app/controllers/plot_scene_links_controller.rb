class PlotSceneLinksController < ApplicationController
  before_action :require_login

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
      redirect_to reader_link_path(@plot, new_link)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def fork
    source_plot = Plot.find(params[:plot_id])
    source_link = PlotSceneLink.find(params[:id])
    return render plain: "Not found", status: :not_found unless source_link.plot_id == source_plot.id
    return render plain: "Login required", status: :unauthorized unless current_user

    begin
      result = PlotForker.new(plot: source_plot, link: source_link, user: current_user).call
      redirect_to reader_link_path(result[:plot], result[:link]), notice: "Forked plot"
    rescue ArgumentError => e
      redirect_to reader_link_path(source_plot, source_link), alert: e.message
    end
  end

  private

  def scene_params
    params.require(:scene).permit(:text)
  end
end
