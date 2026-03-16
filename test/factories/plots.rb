FactoryBot.define do
  factory :plot do
    association :user
    scene { association :scene, text: scene_texts.first }
    sequence(:title) { |n| "Plot #{n}" }

    transient do
      story {
        <<~EOS
        私は目が覚めた。
        ---
        私は眠った。
        EOS
      }
      scene_texts { story.split("---").map(&:strip) }
    end

    after(:create) do |plot, evaluator|
      scenes = [ plot.scene ]
      evaluator.scene_texts.slice(1..).each do |text|
        scenes << create(:scene, user: plot.user, text:)
      end

      scenes.each_with_index do |scene, i|
        create(:plot_scene_link, plot:, scene:, next_scene: scenes[i + 1])
      end
    end
  end
end
