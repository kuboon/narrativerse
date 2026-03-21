# frozen_string_literal: true

module RubyLLM
  # Test provider that reuses Bedrock's Chat/Media modules for payload
  # rendering and response parsing, but replaces HTTP transport with
  # Faraday's test adapter so no real network calls are made.
  #
  # Usage in tests:
  #
  #   RubyLLM::StubProvider.stub_chat("Hello!") do
  #     chat.ask("Hi")
  #   end
  #
  class StubProvider < Provider
    include Providers::Bedrock::Chat
    include Providers::Bedrock::Media

    # -- Provider identity ------------------------------------------------

    def api_base
      "https://stub.test"
    end

    def headers
      {}
    end

    class << self
      def slug                       = "stub"
      def configuration_requirements = []
      def local?                     = true
      def assume_models_exist?       = true

      # Register a Bedrock-formatted response body for the duration of
      # the block.  Accepts either a plain text string (auto-wrapped)
      # or a full Bedrock Converse response hash.
      #
      #   StubProvider.stub_chat("Hello!")
      #   StubProvider.stub_chat({ "output" => { ... }, "usage" => { ... } })
      #
      def stub_chat(body, &block)
        response_body = body.is_a?(Hash) ? body : bedrock_response(body)
        stubs = Faraday::Adapter::Test::Stubs.new do |stub|
          stub.post(%r{/model/.+/converse}) do
            [ 200, { "Content-Type" => "application/json" }, response_body ]
          end
        end

        if block_given?
          begin
            Thread.current[:stub_provider_stubs] = stubs
            yield
          ensure
            Thread.current[:stub_provider_stubs] = nil
          end
        else
          Thread.current[:stub_provider_stubs] = stubs
        end
      end

      def clear_stubs
        Thread.current[:stub_provider_stubs] = nil
      end

      # Build a minimal Bedrock Converse response hash from a text string.
      def bedrock_response(text, model_id: "stub-model", input_tokens: 10, output_tokens: 20)
        {
          "output" => {
            "message" => {
              "role" => "assistant",
              "content" => [ { "text" => text } ]
            }
          },
          "usage" => {
            "inputTokens" => input_tokens,
            "outputTokens" => output_tokens
          },
          "modelId" => model_id
        }
      end

      # Build a Bedrock Converse response with a tool call.
      def bedrock_tool_call(tool_use_id:, name:, input: {}, model_id: "stub-model")
        {
          "output" => {
            "message" => {
              "role" => "assistant",
              "content" => [
                {
                  "toolUse" => {
                    "toolUseId" => tool_use_id,
                    "name" => name,
                    "input" => input
                  }
                }
              ]
            }
          },
          "usage" => { "inputTokens" => 10, "outputTokens" => 20 },
          "modelId" => model_id
        }
      end

      # Access the current thread-local stubs (used by the instance).
      def current_stubs
        Thread.current[:stub_provider_stubs]
      end
    end

    # -- Initialization ---------------------------------------------------

    def initialize(config)
      @config = config
    end

    def connection
      stubs = self.class.current_stubs || default_stubs
      Faraday.new(url: api_base) do |f|
        f.request  :json
        f.response :json
        f.adapter  :test, stubs
      end
    end

    # -- Chat completion --------------------------------------------------

    def complete(messages, tools:, temperature:, model:, params: {}, headers: {}, schema: nil, thinking: nil, tool_prefs: nil, &block)
      payload = Utils.deep_merge(
        render_payload(
          messages,
          tools: tools,
          temperature: temperature,
          model: model,
          stream: block_given?,
          schema: schema,
          thinking: thinking
        ),
        params
      )

      response = connection.post(completion_url, payload)
      result = parse_completion_response(response)

      if block_given?
        yield result
      end

      result
    end

    # -- Models -----------------------------------------------------------

    def list_models = []

    private

    def default_stubs
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post(%r{/model/.+/converse}) do
          body = self.class.bedrock_response("(no stub registered)")
          [ 200, { "Content-Type" => "application/json" }, body ]
        end
      end
    end
  end

  Provider.register(:stub, StubProvider)

  # Monkey-patch RubyLLM::Models.resolve to always use the :stub provider in test environment.
  # This ensures that all LLM calls (Chat, Embedding, etc.) are routed through the StubProvider
  # unless a provider is explicitly specified (though even then, we might want to force :stub).
  class Models
    class << self
      alias_method :original_resolve, :resolve

      def resolve(model_id, provider: nil, assume_exists: false, config: nil)
        if Rails.env.test?
          # Always force the :stub provider in tests to prevent accidental real API calls.
          provider = :stub
          assume_exists = true
        end
        original_resolve(model_id, provider: provider, assume_exists: assume_exists, config: config)
      end
    end
  end
end
