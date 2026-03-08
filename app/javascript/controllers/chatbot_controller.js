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

    let currentLeaderDetails = null

    rows.forEach((row) => {
      if (row.dataset.messageKind !== "thinking") {
        currentLeaderDetails = null
        row.classList.remove("thinking-continuation")
        return
      }

      const myDetails = row.querySelector("details")
      const myContent = row.querySelector("details > div")

      if (!currentLeaderDetails) {
        // This is the first thinking message in a sequence
        currentLeaderDetails = myContent
        row.classList.remove("thinking-continuation")
        return
      }

      // This is a continuation
      row.classList.add("thinking-continuation")

      if (myContent && !myContent.dataset.moved) {
        // Move all children of this thinking details into the leader's details
        const separator = document.createElement("div")
        separator.className = "my-3 border-t border-base-content/10 pt-3"
        currentLeaderDetails.appendChild(separator)

        while (myContent.firstChild) {
          currentLeaderDetails.appendChild(myContent.firstChild)
        }
        myContent.dataset.moved = "true"
        
        // Auto-open the leader if a new Turn is added, so user sees something is happening
        const leaderDetails = currentLeaderDetails.closest("details")
        if (leaderDetails) {
          leaderDetails.open = true
        }
      }
    })
  }

  attachThinkingMessageObserver() {
    if (!this.hasMessagesTarget) return

    this.observer = new MutationObserver(() => {
      this.applyThinkingMessageGrouping()
    })

    this.observer.observe(this.messagesTarget, { childList: true })
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
