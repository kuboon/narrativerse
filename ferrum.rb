require "ferrum"
browser = Ferrum::Browser.new(browser_options: { 'no-sandbox': nil })
browser.go_to("https://google.com")
browser.screenshot(path: "tmp/screenshots/google.png")
browser.quit
