FactoryBot.define do
  factory :chat do
    transient do
      messages_count { 3 }
    end
    messages do |_, chat|
      m1 = build(:message, chat:, role: :system, content: "プロットの要素を追加していきましょう。")
      m3 = build(:message, :with_choices, chat:)
      m2 = build(:message, chat:)
      [ m1, m2, m3 ].take(messages_count)
    end
    association :user
  end
end
