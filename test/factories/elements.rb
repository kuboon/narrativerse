FactoryBot.define do
  factory :element do
    association :user
    element_type { "Character" }
    sequence(:name) { |n| "Element #{n}" }
    after(:build) do |element|
      element.build_latest_revision(user: element.user, revision: 1, appearance: "外見の説明", description: "詳細な説明")
    end
  end
end
