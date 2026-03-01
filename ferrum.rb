require "ferrum"

browser = Ferrum::Browser.new(
	browser_path: ENV["BROWSER_PATH"],
	process_timeout: ENV.fetch("FERRUM_PROCESS_TIMEOUT", 30).to_i,
	timeout: ENV.fetch("FERRUM_DEFAULT_TIMEOUT", 15).to_i,
	browser_options: {
		'no-sandbox': nil,
		'disable-setuid-sandbox': nil,
		'disable-dev-shm-usage': nil,
		'disable-gpu': nil,
		'no-first-run': nil,
		'no-default-browser-check': nil,
		'headless': 'new'
	}
)
browser.go_to("https://google.com")
browser.screenshot(path: "tmp/screenshots/google.png")
browser.quit
