RubyLLM.configure do |config|
  config.openai_api_key = Rails.application.credentials.dig(:openai_api_key)
  config.default_model = "gpt-5-nano"

  # Use the new association-based acts_as API (recommended)
  config.use_new_acts_as = true
end
module RubyLLM
  class StubProvider < Provider
    def chat(messages, options = {})
      # Return a fixed response for testing purposes
      "This is a stubbed response to: #{messages.last[:content]}"
    end

    def api_base = nil
    def list_models = []
    def self.local? = true
  end
  Provider.register(:stub, StubProvider)
end
