# frozen_string_literal: true

module PlotWriter
  module Tools
    module ForRubyLLM
      class CrudSceneTool < Base
        wraps PlotWriter::Tools::CrudSceneTool

        def execute(**)
          res = super(**)
          return halt(res["message"]) if res["status"] == "ok"
          res
        end
      end
    end
  end
end
