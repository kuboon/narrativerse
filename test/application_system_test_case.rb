require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 400, 400 ] do |driver_option|
    driver_option.binary = ENV["CHROME_BIN"] if ENV["CHROME_BIN"].present?
  end
end
