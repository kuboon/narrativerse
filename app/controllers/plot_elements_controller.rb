class PlotElementsController < ApplicationController
  before_action :require_login
  before_action :set_plot
  before_action :authorize_plot
  before_action :set_plot_element, only: [:edit, :update, :destroy]

  def new
    @plot_element = @plot.plot_elements.new
    load_elements
  end

  def create
    element = Element.find(plot_element_params[:element_id])
    revision = element.latest_revision

    @plot_element = @plot.plot_elements.new(
      element: element,
      element_revision: revision,
      summary: plot_element_params[:summary],
      secrets: plot_element_params[:secrets]
    )

    if @plot_element.save
      redirect_to plot_path(@plot), notice: "Element added"
    else
      load_elements
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @plot_element.update(plot_element_update_params)
      redirect_to plot_path(@plot), notice: "Element updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @plot_element.destroy
    redirect_to plot_path(@plot), notice: "Element removed"
  end

  private

  def set_plot
    @plot = Plot.find(params[:plot_id])
  end

  def authorize_plot
    return if @plot.user == current_user

    redirect_to plot_path(@plot), alert: "Forbidden"
  end

  def set_plot_element
    @plot_element = @plot.plot_elements.find(params[:id])
  end

  def load_elements
    @query = params[:q].to_s.strip
    @element_types = Element::ELEMENT_TYPES
    @selected_types = Array(params[:types]).presence || @element_types

    scope = Element.order(created_at: :desc)
    scope = scope.where(element_type: @selected_types) if @selected_types.any?

    if @query.present?
      query = "%#{@query}%"
      scope = scope.left_joins(:element_revisions)
                   .where("elements.name LIKE ? OR element_revisions.summary LIKE ? OR element_revisions.text LIKE ?", query, query, query)
                   .distinct
    end

    @elements = scope.limit(50).includes(:element_revisions)
  end

  def plot_element_params
    params.require(:plot_element).permit(:element_id, :summary, :secrets)
  end

  def plot_element_update_params
    params.require(:plot_element).permit(:summary, :secrets)
  end
end
