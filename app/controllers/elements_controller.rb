class ElementsController < ApplicationController
  before_action :require_login, except: [:index, :show]
  before_action :set_element, only: :show

  def index
    @elements = Element.order(created_at: :desc)
  end

  def show
    @latest_revision = @element.latest_revision
  end

  def new
    @element = Element.new
  end

  def create
    @element = Element.new(element_params)
    @element.user = current_user

    if @element.save
      revision = ElementRevisionManager.new(
        element: @element,
        user: current_user,
        revision_params: revision_params
      ).create_initial
      if revision.persisted?
        redirect_to @element, notice: "Element created"
      else
        @element.destroy
        render :new, status: :unprocessable_entity
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @element = current_user.elements.find(params[:id])
    @revision = @element.latest_revision
  end

  def update
    @element = current_user.elements.find(params[:id])

    if @element.update(element_params)
      revision = ElementRevisionManager.new(
        element: @element,
        user: current_user,
        revision_params: revision_params
      ).create_next
      if revision.persisted?
        redirect_to @element, notice: "Element updated"
      else
        @revision = @element.latest_revision
        render :edit, status: :unprocessable_entity
      end
    else
      @revision = @element.latest_revision
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_element
    @element = Element.find(params[:id])
  end

  def element_params
    params.require(:element).permit(:name, :element_type)
  end

  def revision_params
    params.require(:element_revision).permit(:summary, :text)
  end
end
