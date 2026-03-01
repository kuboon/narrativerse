RubyLLM.configure do |config|
  config.openai_api_key = Rails.application.credentials.dig(:openai_api_key)
  config.default_model = "gpt-5-nano"

  # Use the new association-based acts_as API (recommended)
  config.use_new_acts_as = true
end
module RubyLLM
  Provider.register(:stub,
    Class.new(RubyLLM::Provider) do
      def chat(messages, options = {})
        # Return a fixed response for testing purposes
        "This is a stubbed response to: #{messages.last[:content]}"
      end
      def api_base = nil
      def self.local? = true
    end
  )
end
