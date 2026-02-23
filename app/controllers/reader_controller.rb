class ReaderController < ApplicationController
  def show
    @plot = Plot.find(params[:plot_id])
    authorize @plot
    story = PlotStory.new(@plot, focus_link_id: params[:link_id]).call
    @story_links = story[:story_links]
    @focus_link = story[:focus_link]
    @branches = story[:branches]
    @plot_elements = @plot.plot_elements.includes(:element, :element_revision)
  end
end
