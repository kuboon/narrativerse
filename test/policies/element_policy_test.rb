require "test_helper"

describe ElementPolicy do
  let(:owner) { User.create!(name: "Owner") }
  let(:other_user) { User.create!(name: "Other") }
  let(:element) { Element.create!(user: owner, element_type: "Character", name: "Hero") }

  it "allows authenticated users to update elements" do
    policy = ElementPolicy.new(other_user, element)

    _(policy.update?).must_equal true
  end

  it "allows owners to manage their elements" do
    policy = ElementPolicy.new(owner, element)

    _(policy.manage?).must_equal true
  end
end
