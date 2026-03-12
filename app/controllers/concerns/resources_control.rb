module ResourcesControl
  extend ActiveSupport::Concern

  included do
    before_action :load_resource, only: member_actions
    before_action :load_parent, only: collection_actions if parent_class
  end

  private

  def self.parent_class = nil
  def self.collection_actions = %i[index new create]
  def self.member_actions = %i[show edit update destroy]

  def load_resource
    @resource = resource_class.find(params[:id])
    authorize @resource
  end
  def load_parent
    @parent = parent_class.find(params["#{parent_class.snake}_id"])
  end

  def resource_class
    controller_name.classify.constantize
  end
end
