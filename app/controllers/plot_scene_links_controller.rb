class PlotSceneLinksController < ApplicationController
  before_action :require_login

  def new
    @plot = Plot.find(params[:plot_id])
    authorize @plot, :manage_story?

    # This screen is deprecated — redirect to the plot show page.
    redirect_to plot_path(@plot)
  end

  def create
    @plot = Plot.find(params[:plot_id])
    authorize @plot, :manage_story?

    @scene = Scene.new(scene_params)
    @scene.user = current_user

    if @scene.save
      last_link = PlotSceneLink.find_by(plot_id: @plot.id, next_scene_id: nil)
      last_link.update!(next_scene_id: @scene.id) if last_link
      @link = PlotSceneLink.create!(plot: @plot, scene: @scene, next_scene_id: nil)

      respond_to do |format|
        format.html { redirect_to reader_link_path(@plot, @link) }
        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def fork
    source_plot = Plot.find(params[:plot_id])
    source_link = PlotSceneLink.find(params[:id])
    return render plain: "見つかりません", status: :not_found unless source_link.plot_id == source_plot.id
    authorize source_plot, :fork?

    begin
      result = PlotForker.new(plot: source_plot, link: source_link, user: current_user).call
      redirect_to reader_link_path(result[:plot], result[:link]), notice: "分岐プロットを作成しました"
    rescue ArgumentError => e
      redirect_to reader_link_path(source_plot, source_link), alert: e.message
    end
  end

  # Allow updating the linked scene in the context of this plot/link.
  # If the current user owns the plot, update the scene directly (no COW).
  # Otherwise editing is forbidden here.
  def update
    @link = PlotSceneLink.find(params[:id])
    @plot = @link.plot

    unless @plot && @plot.user_id == current_user.id
      head :forbidden
      return
    end

    new_text = scene_params[:text]

    @link.scene.update!(text: new_text)

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
