require "test_helper"

class StubProviderTest < ActiveSupport::TestCase
  extend Minitest::Spec::DSL

  let(:provider) { RubyLLM::StubProvider.new(RubyLLM.config) }
  let(:model) do
    RubyLLM::Model::Info.new(
      id: "stub-model",
      name: "Stub Model",
      provider: "stub",
      family: "stub",
      created_at: nil,
      context_window: 128_000,
      max_output_tokens: 4096,
      modalities: { input: %w[text], output: %w[text] },
      capabilities: [],
      pricing: {},
      metadata: {}
    )
  end

  it "returns stubbed text response via Bedrock Converse format" do
    RubyLLM::StubProvider.stub_chat("こんにちは！") do
      messages = [ RubyLLM::Message.new(role: :user, content: "Hello") ]
      result = provider.complete(messages, tools: {}, temperature: 0.7, model: model)

      _(result).must_be_kind_of RubyLLM::Message
      _(result.role).must_equal :assistant
      _(result.content).must_equal "こんにちは！"
      _(result.input_tokens).must_equal 10
      _(result.output_tokens).must_equal 20
    end
  end

  it "returns stubbed tool call response" do
    response = {
      "output" => {
        "message" => {
          "role" => "assistant",
          "content" => [
            {
              "toolUse" => {
                "toolUseId" => "tool_abc",
                "name" => "list_scenes",
                "input" => { "plot_id" => 42 }
              }
            }
          ]
        }
      },
      "usage" => { "inputTokens" => 5, "outputTokens" => 15 },
      "modelId" => "stub-model"
    }

    RubyLLM::StubProvider.stub_chat(response) do
      messages = [ RubyLLM::Message.new(role: :user, content: "シーン一覧") ]
      result = provider.complete(messages, tools: {}, temperature: 0.7, model: model)

      _(result.tool_calls).wont_be_nil
      tool_call = result.tool_calls["tool_abc"]
      _(tool_call.name).must_equal "list_scenes"
      _(tool_call.arguments).must_equal({ "plot_id" => 42 })
    end
  end

  it "returns default response when stub_chat is not active" do
    messages = [ RubyLLM::Message.new(role: :user, content: "Hi") ]
    result = provider.complete(messages, tools: {}, temperature: 0.7, model: model)

    _(result.content).must_equal "(no stub registered)"
  end

  it "renders system messages and multi-turn conversation" do
    RubyLLM::StubProvider.stub_chat("了解しました。") do
      messages = [
        RubyLLM::Message.new(role: :system, content: "あなたは物語作家です。"),
        RubyLLM::Message.new(role: :user, content: "新しい物語を作って"),
        RubyLLM::Message.new(role: :assistant, content: "どんなジャンルですか？"),
        RubyLLM::Message.new(role: :user, content: "ファンタジー")
      ]
      result = provider.complete(messages, tools: {}, temperature: 0.5, model: model)

      _(result.content).must_equal "了解しました。"
    end
  end

  it "is registered as :stub provider" do
    _(RubyLLM::Provider.resolve(:stub)).must_equal RubyLLM::StubProvider
  end

  it "is a local provider" do
    _(RubyLLM::StubProvider.local?).must_equal true
  end

  it "assumes models exist" do
    _(RubyLLM::StubProvider.assume_models_exist?).must_equal true
  end

  it "has no configuration requirements" do
    _(RubyLLM::StubProvider.configuration_requirements).must_equal []
  end

  it "automatically redirects all Models.resolve calls to :stub in test environment" do
    model_info, provider_instance = RubyLLM::Models.resolve("gpt-5-nano")
    _(provider_instance).must_be_kind_of RubyLLM::StubProvider
    _(model_info.id).must_equal "gpt-5-nano"
  end
end
