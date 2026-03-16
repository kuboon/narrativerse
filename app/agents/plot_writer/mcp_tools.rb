# frozen_string_literal: true

module PlotWriter
  module McpTools
    module_function

    def all
      [
        CrudSceneTool,
        CrudElementTool,
        SearchElementsTool
      ]
    end
  end
end
