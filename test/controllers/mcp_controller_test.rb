require "test_helper"

class McpControllerTest < ActionDispatch::IntegrationTest
  extend Minitest::Spec::DSL

  it "redirects to login when not logged in" do
    post mcp_path, params: {
      jsonrpc: "2.0",
      id: "1",
      method: "ping"
    }, as: :json

    assert_redirected_to new_session_path
  end

  it "responds to initialize request when logged in" do
    user = create(:user)
    plot = create(:plot, user:)

    post session_path, params: { user_id: user.id }
    post mcp_path(plot_id: plot.id), params: {
      jsonrpc: "2.0",
      id: "1",
      method: "initialize",
      params: {
        protocolVersion: "2025-06-18",
        capabilities: {},
        clientInfo: {
          name: "test-client",
          version: "1.0.0"
        }
      }
    }.to_json, headers: {
      "CONTENT_TYPE" => "application/json",
      "ACCEPT" => "application/json, text/event-stream"
    }

    assert_response :success

    body = JSON.parse(response.body)
    assert_equal "2.0", body.fetch("jsonrpc")
    assert_equal "1", body.fetch("id")
    assert body.fetch("result").key?("serverInfo")
  end
end
