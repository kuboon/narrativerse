ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/spec"
require "capybara/cuprite"

ferrum_process_timeout = ENV.fetch("FERRUM_PROCESS_TIMEOUT", 30).to_i
ferrum_default_timeout = ENV.fetch("FERRUM_DEFAULT_TIMEOUT", 120).to_i
ferrum_browser_path = ENV["BROWSER_PATH"]
ferrum_logger = ENV["FERRUM_DEBUG_LOG"] == "1" ? $stdout : nil
ferrum_browser_options = {
  'no-sandbox': nil,
  'disable-setuid-sandbox': nil,
  'disable-dev-shm-usage': nil,
  'disable-gpu': nil,
  'no-first-run': nil,
  'no-default-browser-check': nil
}

if ENV["FERRUM_DEBUG_LOG"] == "1"
  ferrum_browser_options['enable-logging'] = 'stderr'
  ferrum_browser_options['v'] = '1'
end

Capybara.javascript_driver = :cuprite
Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(app,
    process_timeout: ferrum_process_timeout,
    timeout: ferrum_default_timeout,
    browser_path: ferrum_browser_path,
    browser_options: ferrum_browser_options,
    headless: true
  )
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
