# frozen_string_literal: true

module PlotWriter
  module McpTools
    class BaseTool < MCP::Tool
      class << self
        attr_reader :ruby_llm_tool_class

        def wraps(tool_class)
          @ruby_llm_tool_class = tool_class
        end

        private

        def call_wrapped(arguments:, server_context:)
          context = resolve_context(server_context)
          return error_response(context[:error]) if context[:error]

          tool = ruby_llm_tool_class.new(user: context[:user], plot: context[:plot])
          payload = normalize_payload(tool.call(arguments))

          response(payload)
        rescue StandardError => e
          error_response(e.message)
        end

        def resolve_context(server_context)
          context = normalize_context(server_context)

          user = context[:user] || User.find_by(id: context[:user_id])
          return { error: "ユーザーが見つかりません。" } unless user

          plot = context[:plot] || Plot.find_by(id: context[:plot_id])
          return { error: "プロットが見つかりません。" } unless plot

          { user:, plot: }
        end

        def normalize_context(server_context)
          raw = if server_context.respond_to?(:to_h)
            server_context.to_h
          else
            server_context || {}
          end

          raw.respond_to?(:transform_keys) ? raw.transform_keys(&:to_sym) : {}
        end

        def normalize_payload(raw)
          payload = case raw
          when Hash
            raw.respond_to?(:deep_symbolize_keys) ? raw.deep_symbolize_keys : raw
          when String
            JSON.parse(raw, symbolize_names: true)
          else
            { status: "ok", result: raw }
          end

          if payload.is_a?(Hash) && payload.key?(:error)
            { status: "error", message: payload[:error] }
          else
            payload
          end
        rescue JSON::ParserError
          { status: "ok", result: raw.to_s }
        end

        def response(payload)
          MCP::Tool::Response.new(
            [ { type: "text", text: JSON.generate(payload) } ],
            structured_content: payload,
            error: payload[:status] == "error"
          )
        end

        def error_response(message)
          payload = { status: "error", message: }
          response(payload)
        end
      end
    end
  end
end
