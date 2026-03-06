require "test_helper"

class PlotTest < ActiveSupport::TestCase
  extend Minitest::Spec::DSL

  let(:user) { create(:user) }
  let(:scene) { create(:scene, user:) }

  it "allows ruby and bold in title and summary" do
    plot = build(
      :plot,
      user:,
      scene:,
      title: "<p><strong>勇者</strong></p>",
      summary: "<p><ruby>旅路<rt>たびじ</rt></ruby></p>"
    )

    assert plot.valid?
    assert_includes plot.title, "<strong>"
    assert_includes plot.summary, "<ruby>"
  end

  it "allows blank title and nil scene for draft" do
    plot = build(:plot, user:, scene: nil, title: "<p> </p>")

    assert plot.valid?
    assert_nil plot.title
    assert_nil plot.scene_id
  end

  it "validates summary length using plain text" do
    long_text = "あ" * 201
    plot = build(:plot, user:, scene:, summary: "<p><strong>#{long_text}</strong></p>")

    refute plot.valid?
    assert plot.errors[:summary].any?
  end
end
