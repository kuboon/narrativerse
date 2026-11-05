import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Submits the chat form with fetch and applies each Server-Sent Event's
// data as a Turbo Stream message while the response is still streaming.
export default class extends Controller {
  static targets = ["content", "submit"]

  async submit(event) {
    event.preventDefault()
    if (this.busy || this.contentTarget.value.trim() === "") return

    const body = new FormData(this.element)
    this.contentTarget.value = ""
    this.setBusy(true)

    try {
      const response = await fetch(this.element.action, {
        method: "POST",
        body,
        headers: { Accept: "text/event-stream" },
        credentials: "same-origin"
      })
      if (!response.ok || !response.body) {
        this.contentTarget.value ||= body.get("message[content]")
        throw new Error(`HTTP ${response.status}`)
      }

      await this.readEvents(response.body, (data) => Turbo.renderStreamMessage(data))
    } catch (error) {
      console.error("chat stream failed", error)
    } finally {
      this.setBusy(false)
    }
  }

  async readEvents(stream, onData) {
    const reader = stream.pipeThrough(new TextDecoderStream()).getReader()
    let buffer = ""

    for (;;) {
      const { value, done } = await reader.read()
      if (done) break

      buffer = (buffer + value).replace(/\r\n?/g, "\n")
      let boundary
      while ((boundary = buffer.indexOf("\n\n")) !== -1) {
        const data = this.parseEvent(buffer.slice(0, boundary))
        buffer = buffer.slice(boundary + 2)
        if (data !== null) onData(data)
      }
    }
  }

  parseEvent(block) {
    const lines = block.split("\n").filter((line) => line.startsWith("data:"))
    if (lines.length === 0) return null

    return lines.map((line) => line.slice(5).replace(/^ /, "")).join("\n")
  }

  setBusy(busy) {
    this.busy = busy
    if (!this.hasSubmitTarget) return

    this.submitTarget.disabled = busy
    this.submitTarget.value = busy ? "送信中" : "送信"
  }
}
