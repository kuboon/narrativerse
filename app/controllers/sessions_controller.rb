class SessionsController < ApplicationController
  def new
    @users = User.order(created_at: :desc)
  end

  def create
    user = User.find_by(id: params[:user_id])

    if user
      session[:user_id] = user.id
      redirect_to root_path, notice: "Logged in"
    else
      redirect_to new_session_path, alert: "User not found"
    end
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "Logged out"
  end
end
