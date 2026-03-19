class McpController < ApplicationController
  before_action :require_mcp_user
  skip_before_action :verify_authenticity_token, only: :create

  def create
    server = PlotWriter::McpServer.new(
      user: @mcp_user,
      plot: @mcp_user.plots.latest
    )

    transport = MCP::Server::Transports::StreamableHTTPTransport.new(server)
    server.transport = transport

    status, headers_, body = transport.handle_request(request)
    headers = response_headers(headers_)
    payload = body.respond_to?(:first) ? body.first : body

    return head status, headers: headers if payload.nil?

    render json: payload, status: status, headers:
  end

  private

  def require_mcp_user
    user_id = McpAuth.verify_user_id(params[:signature])
    @mcp_user = User.find_by(id: user_id)
    return if @mcp_user

    render json: { error: "Unauthorized" }, status: :unauthorized
  end

  def response_headers(headers)
    headers.to_h.except("Content-Type", "content-type", "Content-Length", "content-length")
  end
end
