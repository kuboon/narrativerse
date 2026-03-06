require "test_helper"

class Dev::UiFeedbacksControllerTest < ActionDispatch::IntegrationTest
  extend Minitest::Spec::DSL

  let(:worker_suffix) { ENV.fetch("TEST_ENV_NUMBER", "").presence || "1" }
  let(:feedback_dir) { Rails.root.join("tmp", "ui_feedbacks", "worker_#{worker_suffix}") }
  let(:latest_path) { feedback_dir.join("latest.json") }
  let(:history_path) { feedback_dir.join("history.ndjson") }

  setup do
    FileUtils.rm_f(latest_path)
    FileUtils.rm_f(history_path)
  end

  teardown do
    FileUtils.rm_f(latest_path)
    FileUtils.rm_f(history_path)
  end

  it "stores the latest feedback payload and appends history" do
    post dev_ui_feedbacks_path, params: {
      request: "ここの色を変えたい",
      url: "http://localhost:3000/plots/1",
      page_controller: "plots",
      page_action: "show",
      selector: ".card-title",
      tag_name: "h2",
      text: "勇者の帰還",
      styles: {
        "color" => "rgb(15, 23, 42)"
      }
    }, as: :json

    assert_response :success

    response_body = JSON.parse(response.body)
    assert_equal "ok", response_body.fetch("status")
    assert_equal latest_path.relative_path_from(Rails.root).to_s, response_body.fetch("saved_to")

    assert File.exist?(latest_path)
    assert File.exist?(history_path)

    latest = JSON.parse(File.read(latest_path))
    assert_equal "ここの色を変えたい", latest.fetch("request")
    assert_equal ".card-title", latest.fetch("selector")
    assert_equal "plots", latest.fetch("page_controller")
    assert_equal "show", latest.fetch("page_action")
    assert_includes latest.keys, "captured_at"

    history_line = File.readlines(history_path).last
    history = JSON.parse(history_line)
    assert_equal "h2", history.fetch("tag_name")
  end

  it "accepts payload nested under ui_feedback key" do
    post dev_ui_feedbacks_path, params: {
      ui_feedback: {
        request: "この .field のデザインが崩れている",
        url: "http://127.0.0.1:3000/plots/1/plot_elements/new",
        page_controller: "plot_elements",
        page_action: "new",
        selector: ".field",
        tag_name: "div",
        text: ""
      }
    }, as: :json

    assert_response :success

    latest = JSON.parse(File.read(latest_path))
    assert_equal "この .field のデザインが崩れている", latest.fetch("request")
    assert_equal ".field", latest.fetch("selector")
    assert_equal "plot_elements", latest.fetch("page_controller")
    assert_equal "new", latest.fetch("page_action")
  end
end
