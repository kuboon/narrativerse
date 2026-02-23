require "test_helper"

describe PlotPolicy do
  let(:owner) { User.create!(name: "Owner") }
  let(:other_user) { User.create!(name: "Other") }
  let(:scene) { Scene.create!(user: owner, text: "Scene") }
  let(:plot) { Plot.create!(user: owner, title: "Plot", scene: scene) }
  let(:link) { PlotSceneLink.create!(plot: plot, scene: scene, next_scene: nil) }

  it "allows owners to manage story and elements" do
    link
    policy = PlotPolicy.new(owner, plot)

    _(policy.manage_story?).must_equal true
    _(policy.manage_elements?).must_equal true
  end

  it "allows authenticated users to create plots" do
    policy = PlotPolicy.new(other_user, Plot.new)

    _(policy.create?).must_equal true
  end

  it "prevents forking own lineage" do
    link
    policy = PlotPolicy.new(owner, plot)

    _(policy.fork?).must_equal false
  end

  it "allows fork when outside lineage" do
    link
    policy = PlotPolicy.new(other_user, plot)

    _(policy.fork?).must_equal true
  end
end
