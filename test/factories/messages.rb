FactoryBot.define do
  factory :message do
    association :chat
    role { "user" }
    content { "テストメッセージ" }

    trait :assistant do
      role { "assistant" }
      content { "アシスタントの応答" }
      thinking_text { "assistantの思考" }
    end

    trait :with_choices do
      assistant
      content_raw {
        {
          "question" => "次の展開を選んでください。どの方向で物語を進めますか？",
          "choices" => [
            "A. スマホの異常ログを追跡してアクセス元を特定する調査モードに入る。二人は家庭内のAIとスマホの連携を解き明かす。",
            "B. スマホが彼女の過去のメッセージや感情データを断片的に再生し、二人の関係に不信感が生まれる。対話と信頼の再構築を試みる。",
            "C. 外部の介入者が現れ、スマホを介して家庭のAIを操る陰謀が露わになる。二人は協力して事実を暴く。"
          ]
        }
      }
    end
  end
end
