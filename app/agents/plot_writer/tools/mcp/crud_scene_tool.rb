# frozen_string_literal: true

module PlotWriter
  module Tools
    module Mcp
      class CrudSceneTool < Base
        wraps PlotWriter::Tools::CrudSceneTool

        class << self
          def call(scene_id: nil, text: nil, delete: false, server_context:)
            call_wrapped(arguments: { scene_id:, text:, delete: }, server_context:)
          end
        end
      end
    end
  end
end
