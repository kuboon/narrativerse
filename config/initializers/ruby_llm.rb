RubyLLM.configure do |config|
  config.openai_api_key = ENV["OPENAI_API_KEY"] || Rails.application.credentials.dig(:openai_api_key) || "dummy_key_for_test"
  config.anthropic_api_key = ENV["ANTHROPIC_API_KEY"] || "dummy_key_for_test"
  config.default_model = "gpt-5-nano"

  # Use the new association-based acts_as API (recommended)
  config.use_new_acts_as = true
end
