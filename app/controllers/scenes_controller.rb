class ScenesController < ApplicationController
  before_action :require_login

  def update
    @scene = Scene.find(params[:id])

    # We need the context of the plot and the specific link being edited to handle COW properly
    @plot = Plot.find_by(id: params[:plot_id])
    @link = PlotSceneLink.find_by(id: params[:link_id])

    unless @plot && @plot.user_id == current_user.id
      head :forbidden
      return
    end

    # If we have a specific link context, we can do COW
    if @link && @link.plot_id == @plot.id && @link.scene_id == @scene.id
      new_text = scene_params[:text]

      # Always COW if shared or not owned
      is_shared = @scene.plot_scene_links.count > 1 || @scene.plots.count > 1

      if is_shared || @scene.user_id != current_user.id
        @new_scene = Scene.create!(text: new_text, user: current_user)
        @link.update!(scene: @new_scene)
        @scene = @new_scene
      else
        @scene.update!(text: new_text)
      end

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
    else
      # Fallback or error if context missing
      head :unprocessable_entity
    end
  end

  private

  def scene_params
    params.require(:scene).permit(:text)
  end
end
