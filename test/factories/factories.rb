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

    transient do
      scenes_count { 1 }
    end

    after(:create) do |plot, evaluator|
      scenes = [ plot.scene ]
      (evaluator.scenes_count - 1).times do
        scenes << create(:scene, user: plot.user)
      end
      scenes.each_with_index do |scene, i|
        create(:plot_scene_link, plot:, scene:, next_scene: scenes[i + 1])
      end
    end
  end

  factory :plot_scene_link do
    association :plot
    association :scene
  end
end
