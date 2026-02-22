class ScenesController < ApplicationController
  def index
    redirect_to plots_path, notice: "Scenes are managed inside plots now."
  end
end
