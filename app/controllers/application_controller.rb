class ApplicationController < ActionController::Base
  include Pundit::Authorization
  # after_action :verify_authorized

  # Allow dev tool on development
  allow_browser versions: :modern if Rails.env.production?

  helper_method :current_user

  private

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = User.find_by(id: session[:user_id])
  end

  def require_login
    return if current_user

    redirect_to new_session_path, alert: "ログインが必要です"
  end

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def user_not_authorized
    redirect_to request.referer || root_path, alert: "権限がありません"
  end
end
