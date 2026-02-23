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
    return false unless user.present?
    return false if record.user_id == user.id

    PlotNavigation.new(record).plot_chain.none? { |plot| plot.user_id == user.id }
  end

  def manage_story?
    update?
  end

  def manage_elements?
    update?
  end
end
