FactoryBot.define do
  factory :element_revision do
    association :element
    user { element.user }
    sequence(:revision)
    sequence :appearance, "要素の見た目 x_1"
    sequence :description, "要素の説明 x_1"
  end
end
