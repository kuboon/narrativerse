class ReaderController < ApplicationController
  def show
    @plot = Plot.find(params[:plot_id])
    story = PlotStory.new(@plot, focus_link_id: params[:link_id]).call
    @story_links = story[:story_links]
    @focus_link = story[:focus_link]
    @branches = story[:branches]
    @fork_allowed = current_user && PlotNavigation.new(@plot).plot_chain.none? { |plot| plot.user_id == current_user.id }
    @owns_plot = current_user == @plot.user
    @plot_elements = @plot.plot_elements.includes(:element, :element_revision)
  end
end
