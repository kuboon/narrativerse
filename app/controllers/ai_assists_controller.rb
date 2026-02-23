class AiAssistsController < ApplicationController
  before_action :require_login

  def element_summary
    redirect_back fallback_location: new_element_path, alert: "AI支援は未設定です"
  end

  def element_text
    redirect_back fallback_location: new_element_path, alert: "AI支援は未設定です"
  end

  def plot_summary
    redirect_back fallback_location: new_plot_path, alert: "AI支援は未設定です"
  end

  def scene_text
    redirect_back fallback_location: new_plot_path, alert: "AI支援は未設定です"
  end
end
