class PlotElementPolicy < ApplicationPolicy
  def plot_policy = PlotPolicy.new(user, record.plot)
  delegate :own?, to: :plot_policy

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(:plot).where(plots: { user_id: user.id })
    end
  end
end
