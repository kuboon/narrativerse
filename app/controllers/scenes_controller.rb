class ScenesController < ApplicationController
  before_action :require_login, except: [ :index, :show ]
  before_action :set_scene, only: :show

  def index
    @query = params[:q].to_s.strip
    @scenes = Scene.order(created_at: :desc)
    if @query.present?
      query = "%#{@query}%"
      @scenes = @scenes.where("text LIKE ?", query)
    end
    @scenes = @scenes.limit(50)
  end

  def show
  end

  def new
    @scene = Scene.new
  end

  def create
    @scene = Scene.new(scene_params)
    @scene.user = current_user

    if @scene.save
      redirect_to @scene, notice: "Scene created"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @scene = current_user.scenes.find(params[:id])
  end

  def update
    @scene = current_user.scenes.find(params[:id])

    if @scene.update(scene_params)
      redirect_to @scene, notice: "Scene updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_scene
    @scene = Scene.find(params[:id])
  end

  def scene_params
    params.require(:scene).permit(:text)
  end
end
