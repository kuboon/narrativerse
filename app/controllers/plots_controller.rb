class PlotsController < ApplicationController
  before_action :require_login, except: [ :index, :show ]
  before_action :set_plot, only: :show

  def index
    @query = params[:q].to_s.strip
    @plots = Plot.order(created_at: :desc)
    if @query.present?
      query = "%#{@query}%"
      @plots = @plots.where("title LIKE ? OR summary LIKE ?", query, query)
    end
    @plots = @plots.limit(50)
  end

  def show
    @owns_plot = current_user == @plot.user
  end


  def new
    @plot = Plot.new
    @scenes = current_user.scenes.order(created_at: :desc)
  end

  def create
    @plot = Plot.new(plot_params)
    @plot.user = current_user

    if @plot.save
      PlotSceneLink.create!(plot: @plot, scene_id: @plot.scene_id, next_scene_id: nil)
      redirect_to @plot, notice: "Plot created"
    else
      @scenes = current_user.scenes.order(created_at: :desc)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @plot = current_user.plots.find(params[:id])
  end

  def update
    @plot = current_user.plots.find(params[:id])

    if @plot.update(plot_update_params)
      redirect_to @plot, notice: "Plot updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_plot
    @plot = Plot.includes(plot_elements: [ :element, :element_revision ]).find(params[:id])
  end

  def plot_params
    params.require(:plot).permit(:title, :summary, :scene_id)
  end

  def plot_update_params
    params.require(:plot).permit(:title, :summary)
  end
end
