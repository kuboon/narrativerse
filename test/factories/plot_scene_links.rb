FactoryBot.define do
  factory :plot_scene_link do
    association :plot
    association :scene
  end
end
