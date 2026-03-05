class PlotScenesController < ApplicationController
  before_action :require_login

  def create
    @plot = Plot.find(params[:plot_id])
    authorize @plot, :manage_story?

    @scene = Scene.new(scene_params)
    @scene.user = current_user

    unless @scene.save
      return render :new, status: :unprocessable_entity
    end

    last_link = PlotSceneLink.find_by(plot_id: @plot.id, next_scene_id: nil)
    last_link.update!(next_scene_id: @scene.id) if last_link
    @link = PlotSceneLink.create!(plot: @plot, scene: @scene, next_scene_id: nil)

    respond_to do |format|
      format.html { redirect_to reader_scene_path(@plot, @scene.id) }
      format.turbo_stream
    end
  end

  def fork
    source_link = PlotSceneLink.find(params[:id])
    source_plot = source_link.plot
    return render plain: "見つかりません", status: :not_found unless source_link.plot_id == source_plot.id

    authorize source_plot, :fork?

    begin
      result = PlotForker.new(plot: source_plot, link: source_link, user: current_user).call
      redirect_to plot_path(result[:plot]), notice: "分岐プロットを作成しました"
    rescue ArgumentError => e
      redirect_to reader_scene_path(source_plot, source_link.scene_id), alert: e.message
    end
  end

  def update
    @link = PlotSceneLink.find(params[:id])
    @plot = @link.plot

    unless @plot && @plot.user_id == current_user.id
      head :forbidden
      return
    end

    @link.scene.update!(text: scene_params[:text])

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "link-#{@link.id}",
          partial: "scenes/panel",
          locals: { link: @link, plot: @plot }
        )
      end
      format.html { redirect_to plot_path(@plot) }
    end
  end

  private

  def scene_params
    params.require(:scene).permit(:text)
  end
end
