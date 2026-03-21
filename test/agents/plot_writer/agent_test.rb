require "test_helper"

class PlotWriterAgentTest < ActiveSupport::TestCase
  extend Minitest::Spec::DSL

  let(:plot) { create(:plot) }
  let(:user) { plot.user }
  let(:agent) { PlotWriter::Agent.chat(user:, plot:) }

  it "raise no error" do
    assert_nothing_raised do
      agent.ask("プロットの要約を教えて") do |chunk|
        # puts "Received chunk: #{chunk.content}"
      end
    end
  end
end
