import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages", "window", "wrapper", "toggle", "input"]
  static values = { autoOpen: Boolean }

  connect() {
    this.boundCloseChat = this.closeChat.bind(this)
    window.addEventListener("message", this.boundCloseChat)

    if (this.autoOpenValue && this.hasWindowTarget) {
      this.windowTarget.classList.remove("hidden")
    }

    this._attachScrollObserver()
  }

  disconnect() {
    if (this._scrollObserver) this._scrollObserver.disconnect()
    window.removeEventListener("message", this.boundCloseChat)
  }

  toggle() {
    if (!this.hasWindowTarget) return
    const wasHidden = this.windowTarget.classList.toggle("hidden")
    // Scroll to bottom when opening the chatbot window
    if (!wasHidden) this._scrollToBottom()
  }

  closeChat(event) {
    if (event.origin !== window.location.origin) return
    if (event.data === "close-chat" && this.hasWindowTarget) {
      this.windowTarget.classList.add("hidden")
    }
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

  // -- private --------------------------------------------------------------

  _scrollToBottom() {
    if (this.hasMessagesTarget) {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    }
  }

  _attachScrollObserver() {
    if (!this.hasMessagesTarget) return

    // Scroll once on initial load
    this._scrollToBottom()

    // Scroll whenever new child nodes are appended (Turbo Stream updates)
    this._scrollObserver = new MutationObserver(() => this._scrollToBottom())
    this._scrollObserver.observe(this.messagesTarget, { childList: true, subtree: true })
  }
}
