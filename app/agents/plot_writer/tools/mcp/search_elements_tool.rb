# frozen_string_literal: true

module PlotWriter
  module Tools
    module Mcp
      class SearchElementsTool < Base
        wraps PlotWriter::Tools::SearchElementsTool

        class << self
          def call(query: nil, element_type: nil, limit: 10, server_context:)
            call_wrapped(arguments: { query:, element_type:, limit: }, server_context:)
          end
        end
      end
    end
  end
end
