FactoryBot.define do
  factory :scene do
    association :user
    text { "Scene text" }
  end
end
