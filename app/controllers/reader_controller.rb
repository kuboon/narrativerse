class ReaderController < ApplicationController
  def show
    @plot = Plot.find(params[:plot_id])
    authorize @plot
    @plot_elements = @plot.plot_elements.includes(:element, :element_revision)

    story = PlotStory.new(@plot)
    @story_links = story.links
    @branches_by_scene_id = story.branches

    @focus_scene_id = params[:scene_id].presence&.to_i || @plot.scene_id
    return if @story_links.any? { |link| link.scene_id == @focus_scene_id }

    @focus_scene_id = @plot.scene_id
  end
end
