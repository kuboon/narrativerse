# frozen_string_literal: true

module PlotWriter
  module Tools
    module ForRubyLLM
      class Base < RubyLLM::Tool
        @pure_tool_class = nil

        class << self
          attr_reader :pure_tool_class

          def wraps(tool_class)
            @pure_tool_class = tool_class
            description(tool_class.description)
            params(**tool_class.schema)
          end

          def schema
            pure_tool_class.schema
          end
        end

        def name
          super.split("--").last
        end

        def execute(**kwargs)
          pure_tool = self.class.pure_tool_class.new(user:, plot:)
          pure_tool.execute(**kwargs)
        end

        private

        attr_reader :user, :plot

        def initialize(user:, plot:)
          @user = user
          @plot = plot
          super()
        end

        def json(val)
          RubyLLM::Content::Raw.new(val)
        end
      end
    end
  end
end
