FactoryBot.define do
  factory :plot_element do
    association :plot
    summary { "役割" }
    secrets { "秘密" }

    element_revision do
      element.latest_revision || association(:element_revision, element:, user: plot.user)
    end
  end
end
