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

const submitChatChoice = (event) => {
	const button = event.target.closest(".chat-choice-btn")
	if (!button) return

	const form = document.getElementById("new_message")
	if (!form) return

	const contentField = form.querySelector("[name='message[content]']")
	if (!contentField) return

	contentField.value = button.dataset.choice || ""
	form.requestSubmit()
}

const installChatChoiceHandler = () => {
	if (document.body?.dataset.chatChoiceHandlerInstalled === "true") return

	document.addEventListener("click", submitChatChoice)
	document.body.dataset.chatChoiceHandlerInstalled = "true"
}

document.addEventListener("turbo:load", () => {
	assignMessagePlotId()
	installChatChoiceHandler()
})
document.addEventListener("turbo:frame-load", assignMessagePlotId)
