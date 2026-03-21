ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/spec"
require_relative "support/stub_provider"
require "capybara/cuprite"

CI = ENV["CI"].present?
puts "Running in CI environment" if CI

browser_options = CI ? {
  'no-sandbox': nil,
  'disable-setuid-sandbox': nil
} : {}

Capybara.javascript_driver = :cuprite
Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(app, { browser_options: })
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    include FactoryBot::Syntax::Methods

    # Add more helper methods to be used by all tests here...
    teardown do
      RubyLLM::StubProvider.clear_stubs
    end
  end
end

module CupriteDriverPatch
  def save_screenshot(path, options = {})
    super
  rescue Ferrum::ProcessTimeoutError => e
    puts e.output
    raise
  end
end
Capybara::Cuprite::Driver.prepend(CupriteDriverPatch)
