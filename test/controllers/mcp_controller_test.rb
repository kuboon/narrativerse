require "test_helper"

class McpControllerTest < ActionDispatch::IntegrationTest
  extend Minitest::Spec::DSL

  it "returns unauthorized without signature" do
    post mcp_path, params: {
      jsonrpc: "2.0",
      id: "1",
      method: "ping"
    }.to_json, headers: {
      "CONTENT_TYPE" => "application/json",
      "ACCEPT" => "application/json, text/event-stream"
    }

    assert_response :unauthorized
  end

  it "responds to initialize request with a valid signature" do
    user = create(:user)
    create(:plot, user:)
    signature = McpAuth.sign_user_id(user.id)

    post mcp_path(signature:), params: {
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
