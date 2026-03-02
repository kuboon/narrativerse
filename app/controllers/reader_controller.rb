class ReaderController < ApplicationController
  def show
    @plot = Plot.find(params[:plot_id])
    authorize @plot
    @focus_scene_id = params[:scene_id] || @plot.scene_id
    @plot_elements = @plot.plot_elements.includes(:element, :element_revision)

    story = PlotStory.new(@plot)
    @story_links = story.links
    @branches_by_scene_id = story.branches
  end
end
