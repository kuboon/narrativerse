require "test_helper"

class PlotWriterAgentTest < ActiveSupport::TestCase
  extend Minitest::Spec::DSL

  let(:plot) { create(:plot) }
  let(:user) { plot.user }
  let(:agent) { PlotWriter::Agent.chat(user:, plot:) }

  it "raise no error" do
    RubyLLM::StubProvider.stub_chat("これはテストの要約です。")
    chunks = []
    result = agent.ask("プロットの要約を教えて") do |chunk|
      chunks << chunk.content
    end
    _(result.content).must_equal "これはテストの要約です。"
    _(chunks).must_include "これはテストの要約です。"
  end

  it "stub is reset after each test" do
    result = agent.ask("Hello")
    _(result.content).must_equal "(no stub registered)"
  end
end
