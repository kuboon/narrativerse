class ScenesController < ApplicationController
  def index
    redirect_to plots_path, notice: "Scene はプロット内で管理されます。"
  end
end
