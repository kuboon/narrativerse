class UsersController < ApplicationController
  before_action :require_login, only: [ :show ]

  def show
    @user = current_user
    @plot_query = params[:plot_q].to_s.strip
    @element_query = params[:element_q].to_s.strip

    @plots = @user.plots.order(created_at: :desc)
    @elements = @user.elements.order(created_at: :desc)

    if @plot_query.present?
      query = "%#{@plot_query}%"
      @plots = @plots.where("title LIKE ? OR summary LIKE ?", query, query)
    end

    if @element_query.present?
      query = "%#{@element_query}%"
      @elements = @elements.where("name LIKE ? OR element_type LIKE ?", query, query)
    end

    @plots = @plots.limit(50)
    @elements = @elements.limit(50)
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      session[:user_id] = @user.id
      redirect_to root_path, notice: "ユーザーを作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :icon, :bio)
  end
end
