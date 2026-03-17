import "@hotwired/turbo-rails"
import "./controllers"

const assignMessagePlotId = () => {
	const form = document.getElementById("new_message")
	if (!form) return

	const plotIdInput = form.querySelector("input[name='message[plot_id]']")
	if (!plotIdInput) return

	const currentUrl = new URL(window.location.href)
	const plotsPathPlotId = currentUrl.pathname.match(/^\/plots\/([^/]+)/)?.[1]
	plotIdInput.value = plotsPathPlotId
}

document.addEventListener("turbo:frame-load", assignMessagePlotId)
