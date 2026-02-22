class ScenesController < ApplicationController
  before_action :require_login, except: [:index, :show]

  def index
    @scenes = Scene.order(created_at: :desc)
  end

  def show
    @scene = Scene.find(params[:id])
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

  def scene_params
    params.require(:scene).permit(:text)
  end
end
