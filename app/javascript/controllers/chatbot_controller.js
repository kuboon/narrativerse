import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages", "window", "wrapper", "toggle", "input"]
  static values = { autoOpen: Boolean }

  connect() {
    this.applyThinkingMessageGrouping()
    this.attachThinkingMessageObserver()

    if (this.autoOpenValue && this.hasWindowTarget) {
      this.windowTarget.classList.remove("hidden")
    }

    this.boundCloseChat = this.closeChat.bind(this)
    window.addEventListener("message", this.boundCloseChat)
  }

  disconnect() {
    if (this.observer) this.observer.disconnect()
    window.removeEventListener("message", this.boundCloseChat)
  }

  toggle() {
    if (this.hasWindowTarget) {
      this.windowTarget.classList.toggle("hidden")
    }
  }

  closeChat(event) {
    if (event.origin !== window.location.origin) return
    if (event.data === "close-chat" && this.hasWindowTarget) {
      this.windowTarget.classList.add("hidden")
    }
  }

  applyThinkingMessageGrouping() {
    if (!this.hasMessagesTarget) return

    const rows = Array.from(this.messagesTarget.children).filter((node) =>
      node.id?.startsWith("message_")
    )

    rows.forEach((row) => row.classList.remove("thinking-continuation"))

    let hasThinkingLeader = false

    rows.forEach((row) => {
      if (row.dataset.messageKind !== "thinking") {
        hasThinkingLeader = false
        return
      }

      if (!hasThinkingLeader) {
        hasThinkingLeader = true
        return
      }

      row.classList.add("thinking-continuation")
    })
  }

  attachThinkingMessageObserver() {
    if (!this.hasMessagesTarget) return

    this.observer = new MutationObserver(() => {
      this.applyThinkingMessageGrouping()
    })

    this.observer.observe(this.messagesTarget, { childList: true, subtree: true })
  }

  selectChoice(event) {
    const button = event.target.closest(".chat-choice-btn")
    if (!button) return

    const value = button.dataset.choice
    if (this.hasInputTarget) {
      this.inputTarget.value = value || ""
      this.inputTarget.form.requestSubmit()
    }
  }
}
