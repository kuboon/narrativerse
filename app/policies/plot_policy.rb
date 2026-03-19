class PlotPolicy < ApplicationPolicy
  def user_id = record.user_id
  def fork? = user.present?
end
