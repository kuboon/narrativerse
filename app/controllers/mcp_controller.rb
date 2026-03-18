class McpController < ApplicationController
  before_action :require_mcp_user
  skip_before_action :verify_authenticity_token, only: :create

  def create
    server = MCP::Server.new(
      name: "narrativerse_plot_writer",
      title: "Narrativerse Plot Writer",
      version: "1.0.0",
      instructions: "Narrativerse のプロット編集を行うための MCP サーバーです。",
      tools: PlotWriter::Tools::Mcp::Base.all,
      prompts: PlotWriter::McpPrompts.all,
      server_context: {
        user_id: @mcp_user.id,
        plot_id: @mcp_user.plots.latest&.id
      }
    )

    transport = MCP::Server::Transports::StreamableHTTPTransport.new(server)
    server.transport = transport

    status, headers, body = transport.handle_request(request)
    payload = body.respond_to?(:first) ? body.first : body

    return head status, headers: response_headers(headers) if payload.nil?

    render json: payload, status: status, headers: response_headers(headers)
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
