FactoryBot.define do
  factory :element_revision do
    association :element
    user { element.user }
    summary { "要素の概要" }
    text { "要素の詳細" }
    revision do
      last_revision = element.element_revisions.maximum(:revision)
      (last_revision || 0) + 1
    end
  end
end
