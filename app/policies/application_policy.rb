# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index? = true

  def show? = index?

  def create? = user.present?
  def new? = create?

  def update? = own?
  def edit? = update?

  def destroy? = own?

  def own? = user.present? && user.id = user_id

  def user_id = raise "not impl"

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.where(user_id: user.id)
    end
  end
end
