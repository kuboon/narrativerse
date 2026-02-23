# frozen_string_literal: true

class ElementPolicy < ApplicationPolicy
  def show?
    true
  end

  def create?
    user.present?
  end

  def update?
    user.present?
  end

  def manage?
    user.present? && record.user_id == user.id
  end
end
