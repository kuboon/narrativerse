# frozen_string_literal: true

module PlotWriter
  module Tools
    module Mcp
      class UpdateElementTool < Base
        wraps PlotWriter::Tools::UpdateElementTool

        class << self
          def call(element_id:, revision: nil, plot_element: nil, server_context:)
            call_wrapped(arguments: { element_id:, revision:, plot_element: }, server_context: server_context)
          end
        end
      end
    end
  end
end
