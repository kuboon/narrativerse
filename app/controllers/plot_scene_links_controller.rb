class PlotSceneLinksController < ApplicationController
  before_action :require_login

  def create(plot_id:)
    @plot = Plot.find(plot_id)
    authorize @plot

    editor = PlotEditor.new(plot: @plot, user: current_user)
    editor.add_scene(text: scene_params[:text])

    head :no_content
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
    link = PlotSceneLink.find(id)
    authorize link
    plot_editor = PlotEditor.new(plot: link.plot, user: current_user)
    plot_editor.update_scene(link:, text: scene_params[:text])

    head :no_content
  rescue ActiveRecord::RecordInvalid => e
    render plain: e.message, status: :unprocessable_entity
  end

  private

  def scene_params
    params.require(:scene).permit(:text)
  end
end
