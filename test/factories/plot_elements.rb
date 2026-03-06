FactoryBot.define do
  factory :plot_element do
    association :plot
    association :element
    summary { "役割" }
    secrets { "秘密" }

    element_revision do
      element.latest_revision || create(:element_revision, element:, user: element.user)
    end
  end
end
