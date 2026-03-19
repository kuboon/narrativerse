class PlotSceneLinkPolicy < ApplicationPolicy
  def user_id = record.plot.user_id

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(:plot).where(plots: { user_id: user.id })
    end
  end
end
