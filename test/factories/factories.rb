FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "User #{n}" }
  end

  factory :scene do
    association :user
    text { "Scene text" }
  end

  factory :plot do
    association :user
    association :scene
    sequence(:title) { |n| "Plot #{n}" }
  end

  factory :plot_scene_link do
    association :plot
    association :scene
  end
end
