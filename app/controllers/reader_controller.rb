class ReaderController < ApplicationController
  def show
    @plot = Plot.find(params[:plot_id])
    authorize @plot
    story = PlotStory.new(@plot).call
    @story_links = story[:story_links]
    @focus_scene_id = params[:scene_id] || @plot.scene_id
    @branches_by_scene_id = story[:branches_by_scene_id]
    @plot_elements = @plot.plot_elements.includes(:element, :element_revision)
  end
end
