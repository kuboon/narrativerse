require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :cuprite, options: {
    browser_options: ENV["CI"].present? ? {
      "no-sandbox": nil,
      "disable-setuid-sandbox": nil
    } : {}
  }
end
