class PlotPolicy < ApplicationPolicy
  def fork? = user.present?
end
