class PlotSceneLinksController < ApplicationController
  before_action :require_login

  def create(plot_id:)
    @plot = Plot.find(plot_id)
    authorize @plot

    editor = PlotEditor.new(plot: @plot, user: current_user)
    link = editor.add_scene(text: scene_params[:text])

    render json: { link_id: link.id, scene_id: link.scene_id }, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render plain: e.message, status: :unprocessable_entity
  end

  def fork(id:)
    source_link = PlotSceneLink.find(id)
    source_plot = source_link.plot
    return render plain: "見つかりません", status: :not_found unless source_link.plot_id == source_plot.id

    authorize source_plot

    begin
      result = PlotEditor.new(plot: source_plot, user: current_user).fork(link: source_link)
      redirect_to plot_path(result[:plot]), notice: "分岐プロットを作成しました"
    rescue ArgumentError => e
      redirect_to reader_path(source_plot, source_link.scene_id), alert: e.message
    end
  end

  def update(id:)
    @link = PlotSceneLink.find(id)
    authorize @link
    @plot = @link.plot

    unless @plot && @plot.user_id == current_user.id
      head :forbidden
      return
    end

    @link.scene.update!(text: scene_params[:text])

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          ActionView::RecordIdentifier.dom_id(@link),
          partial: "plot_scene_links/plot_scene_link",
          locals: { plot_scene_link: @link }
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
