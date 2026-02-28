require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  Selenium::WebDriver::Chrome.path = ENV["CHROME_BIN"] if ENV["CHROME_BIN"].present?

  driven_by :selenium, using: :headless_chrome, screen_size: [ 400, 400 ]
end
