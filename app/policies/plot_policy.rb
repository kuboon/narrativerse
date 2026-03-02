# frozen_string_literal: true

class PlotPolicy < ApplicationPolicy
  def show?
    true
  end

  def create?
    user.present?
  end

  def update?
    user.present? && record.user_id == user.id
  end

  def fork?
    create?
  end

  def manage_story?
    update?
  end

  def manage_elements?
    update?
  end
end
