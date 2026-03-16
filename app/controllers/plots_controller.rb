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
  end


  def new
    authorize Plot

    @plot = current_user.plots.create!
    redirect_to plot_path(@plot), notice: "プロット下書きを作成しました"
  end

  def edit
    authorize @plot
    redirect_to plot_path(@plot)
  end

  def update
    authorize @plot
    @story_links = build_story_links(@plot)

    if @plot.update(plot_update_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            plot_overview_dom_id(@plot),
            partial: "plots/overview",
            locals: { plot: @plot, story_links: @story_links, open_editor: false }
          )
        end
        format.html { redirect_to @plot, notice: "プロットを更新しました" }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            plot_overview_dom_id(@plot),
            partial: "plots/overview",
            locals: { plot: @plot, story_links: @story_links, open_editor: true }
          ), status: :unprocessable_entity
        end
        format.html { render :show, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_plot
    @plot = Plot.includes(plot_elements: [ :element, :element_revision ]).find(params[:id])
  end

  def plot_update_params
    params.require(:plot).permit(:title, :summary)
  end
end
