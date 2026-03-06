FactoryBot.define do
  factory :element do
    association :user
    element_type { "Character" }
    sequence(:name) { |n| "Element #{n}" }

    trait :with_revision do
      after(:create) do |element|
        create(:element_revision, element:, user: element.user)
      end
    end
  end
end
