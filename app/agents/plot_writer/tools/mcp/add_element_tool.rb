# frozen_string_literal: true

module PlotWriter
  module Tools
    module Mcp
      class AddElementTool < Base
        wraps PlotWriter::Tools::AddElementTool

        class << self
          def call(element_id: nil, summary: nil, secrets: nil, server_context:)
            call_wrapped(arguments: { element_id:, summary:, secrets: }, server_context:)
          end
        end
      end
    end
  end
end
