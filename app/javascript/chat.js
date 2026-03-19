const setupChatFrame = () => {
  const frame = document.getElementById("chat-frame")
	const form = frame.querySelector("#new_message")
	if (!form) return
  const contentField = form.querySelector("[name='message[content]']")
  if (!contentField) return

	const plotIdInput = form.querySelector("input[name='message[plot_id]']")
	if (!plotIdInput) return

	const currentUrl = new URL(window.location.href)
	const plotsPathPlotId = currentUrl.pathname.match(/^\/plots\/([^/]+)/)?.[1]
	plotIdInput.value = plotsPathPlotId
 
	if (frame.dataset.chatChoiceHandlerInstalled === "true") return

	frame.addEventListener("click", (event) => {
    const button = event.target.closest(".chat-choice")
    if (!button) return
    
    contentField.value = button.dataset.choice || ""
    form.requestSubmit()
  })
  form.addEventListener("turbo:submit-end", () => {
    contentField.value = ""
  })
	frame.dataset.chatChoiceHandlerInstalled = "true"
}

document.addEventListener("turbo:frame-load", setupChatFrame)
