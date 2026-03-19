class ElementPolicy < ApplicationPolicy
  def user_id = record.user_id
end
