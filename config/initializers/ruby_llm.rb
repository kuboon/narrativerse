RubyLLM.configure do |config|
  config.openai_api_key = Rails.application.credentials.dig(:openai_api_key)
  config.default_model = "gpt-5-nano"
  config.use_new_acts_as = true
end
