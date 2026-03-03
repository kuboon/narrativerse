import { Controller } from "@hotwired/stimulus"
import { Editor } from "@tiptap/core"
import StarterKit from "@tiptap/starter-kit"
import { Ruby } from "tiptap_ruby_extension"

// Connects to data-controller="tiptap"
export default class extends Controller {
  static targets = [ "editor", "toolbar" ]

  connect() {
    const hiddenInput = this.element.querySelector('input[type="hidden"]') || this.element.previousElementSibling
    const editorElement = this.hasEditorTarget ? this.editorTarget : this.element

    this.editor = new Editor({
      element: editorElement,
      extensions: [
        StarterKit,
        Ruby,
      ],
      content: hiddenInput.value,
      onUpdate: ({ editor }) => {
        hiddenInput.value = editor.getHTML()
        editorElement.dispatchEvent(new Event("input", { bubbles: true }))
        this.updateActiveStates()
      },
      onSelectionUpdate: () => {
        this.updateActiveStates()
      },
    })
  }

  updateActiveStates() {
    if (!this.hasToolbarTarget) return
    const buttons = this.toolbarTarget.querySelectorAll("button")
    buttons.forEach(button => {
      const command = button.dataset.command
      if (command) {
        let isActive = false
        if (command === 'heading') {
          const level = parseInt(button.dataset.level)
          isActive = this.editor.isActive(command, { level })
        } else {
          isActive = this.editor.isActive(command)
        }

        if (isActive) {
          button.classList.add("bg-gray-200")
        } else {
          button.classList.remove("bg-gray-200")
        }
      }
    })
  }

  toggleBold(event) {
    event.preventDefault()
    this.editor.chain().focus().toggleBold().run()
  }

  toggleHeading(event) {
    event.preventDefault()
    const level = parseInt(event.currentTarget.dataset.level || 1)
    this.editor.chain().focus().toggleHeading({ level }).run()
  }

  setRuby(event) {
    event.preventDefault()
    if (this.editor.isActive('ruby')) {
      this.editor.chain().focus().unsetRuby().run()
    } else {
      const reading = prompt("ふりがな（ルビ）を入力してください:")
      if (reading) {
        this.editor.chain().focus().setRuby(reading).run()
      }
    }
  }

  disconnect() {
    if (this.editor) {
      this.editor.destroy()
    }
  }
}
