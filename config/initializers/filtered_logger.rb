# frozen_string_literal: true

return unless Rails.env.development?

Rails.application.reloader.to_prepare do
  puts "reload FilteredLogger"
  base_logger = Rails.logger
  base_logger = base_logger.inner_logger while base_logger.respond_to?(:inner_logger)

  Rails.logger = FilteredLogger.new(base_logger)
end
