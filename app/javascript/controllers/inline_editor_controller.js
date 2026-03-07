import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "editor", "form", "input"]

  connect() {
    this.isEditing = !this.editorTarget.classList.contains("hidden")
    this.boundBeforeCache = this.beforeCache.bind(this)
    document.addEventListener("turbo:before-cache", this.boundBeforeCache)
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache", this.boundBeforeCache)
  }

  beforeCache() {
    if (this.isEditing) {
      this.hideEditor()
    }
  }

  edit(event) {
    if (this.isEditing) return
    if (this.clickedInteractiveElement(event.target)) return

    this.stopAllOtherEditors()
    this.showEditor()
  }

  showEditor() {
    this.displayTarget.classList.add("hidden")
    this.editorTarget.classList.remove("hidden")
    this.isEditing = true

    // Focus ProseMirror if available, or first input
    const pmEditor = this.editorTarget.querySelector(".ProseMirror")
    if (pmEditor) {
      pmEditor.focus()
    } else {
      const input = this.inputTargets[0]
      if (input) input.focus()
    }

    this.setInputState("editing")
  }

  hideEditor() {
    this.displayTarget.classList.remove("hidden")
    this.editorTarget.classList.add("hidden")
    this.isEditing = false
  }

  async save() {
    if (!this.isEditing) return

    this.setInputState("saving")
    try {
      await this.submitForm()
      this.setInputState("saved")
      this.hideEditor()
    } catch (error) {
      console.error("Save failed:", error)
      this.setInputState("editing") // Revert to editing state on error
      // Fallback: regular submit if fetch-based submit fails
      if (this.hasFormTarget) this.formTarget.requestSubmit()
    }
  }

  submitForm() {
    return new Promise((resolve, reject) => {
      if (!this.hasFormTarget) return resolve()

      const form = this.formTarget
      if (window.Turbo && typeof form.requestSubmit === "function") {
        // Turbo will handle the submission and the response (likely a Turbo Stream)
        form.requestSubmit()
        resolve()
      } else {
        form.submit()
        resolve()
      }
    })
  }

  setInputState(state) {
    // state: "editing" | "saving" | "saved"
    const classes = ["border-editing", "border-saving", "border-saved"]
    this.inputTargets.forEach(input => {
      input.classList.remove(...classes)
      if (state !== "normal") {
        input.classList.add(`border-${state}`)
      }
    })
  }

  stopAllOtherEditors() {
    const event = new CustomEvent("inline-editor:close-others", { detail: { controller: this } })
    window.dispatchEvent(event)
  }

  closeOthers(event) {
    if (event.detail.controller !== this && this.isEditing) {
      this.save()
    }
  }

  clickOutside(event) {
    if (this.isEditing && !this.element.contains(event.target)) {
      this.save()
    }
  }

  onInput() {
    this.setInputState("editing")
  }

  onKeyDown(event) {
    if (event.key === "Escape") {
      this.hideEditor()
    }
  }

  clickedInteractiveElement(target) {
    return !!target.closest("a, button, summary, input, textarea, select, label, .pm-menu-button")
  }
}
