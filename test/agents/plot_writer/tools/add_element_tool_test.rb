# frozen_string_literal: true

require "test_helper"

module PlotWriter
  module Tools
    class AddElementToolTest < ActiveSupport::TestCase
      setup do
        @plot = create(:plot)
        @user = @plot.user
      end

      test "既存要素をplotへ追加できる" do
        element = create(:element)
        tool = AddElementTool.new(user: @user, plot: @plot)
        result = tool.execute(element: { "element_id" => element.id })
        parsed = JSON.parse(result)
        assert_equal "ok", parsed["status"], parsed["message"]
        assert @plot.plot_elements.any? { |pe| pe.element && pe.element.id == element.id }
      end

      test "新規要素を追加できる" do
        tool = AddElementTool.new(user: @user, plot: @plot)
        result = tool.execute(element: { "element_type" => "Character", "name" => "テストキャラ" })
        parsed = JSON.parse(result)
        assert_equal "ok", parsed["status"], parsed["message"]
        assert @plot.elements.any? { it.name == "テストキャラ" }
      end

      test "要素が見つからない場合はエラー" do
        tool = AddElementTool.new(user: @user, plot: @plot)
        result = tool.execute(element: { "element_id" => -1 })
        parsed = JSON.parse(result)
        assert_equal "error", parsed["status"]
        assert_match /要素が見つかりません/, parsed["message"]
      end
    end
  end
end
