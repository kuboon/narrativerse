class PlotsController < ApplicationController
  before_action :require_login, except: [ :index, :show ]
  before_action :set_plot, only: [ :show, :edit, :update ]

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
    authorize @plot
    @story_links = PlotStory.new(@plot).call[:story_links]
  end


  def new
    @plot = Plot.new
    authorize @plot
    @scenes = current_user.scenes.order(created_at: :desc)
  end

  def create
    @plot = Plot.new(plot_params)
    @plot.user = current_user
    authorize @plot

    if @plot.save
      PlotSceneLink.create!(plot: @plot, scene_id: @plot.scene_id, next_scene_id: nil)
      redirect_to @plot, notice: "プロットを作成しました"
    else
      @scenes = current_user.scenes.order(created_at: :desc)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @plot
  end

  def update
    authorize @plot

    if @plot.update(plot_update_params)
      redirect_to @plot, notice: "プロットを更新しました"
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
