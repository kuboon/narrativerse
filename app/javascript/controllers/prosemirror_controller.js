import { Controller } from "@hotwired/stimulus"
import { Schema } from "prosemirror-model"
import { schema as basicSchema } from "prosemirror-schema-basic"
import { EditorState } from "prosemirror-state"
import { EditorView } from "prosemirror-view"
import { history, undo, redo } from "prosemirror-history"
import { keymap } from "prosemirror-keymap"
import { toggleMark, baseKeymap } from "prosemirror-commands"
import { rubyMark } from "../prosemirror_ruby_mark"

// Build schema: paragraph + text + bold mark + ruby mark
const schema = new Schema({
  nodes: basicSchema.spec.nodes,
  marks: basicSchema.spec.marks.append({ ruby: rubyMark }),
})

const boldMark = schema.marks.strong

function buildKeymap() {
  return keymap({
    ...baseKeymap,
    "Mod-z": undo,
    "Mod-y": redo,
    "Mod-Shift-z": redo,
    "Mod-b": toggleMark(boldMark),
    "Mod-B": toggleMark(boldMark),
  })
}

// Converts a DOM node produced by the server (HTML string in hidden input) into a ProseMirror doc
function htmlToDoc(html) {
  const div = document.createElement("div")
  div.innerHTML = html
  return schema.parseDOM
    ? DOMParser.fromSchema(schema).parse(div)
    : schema.nodes.doc.createAndFill()
}

// Lazy import for DOMParser from prosemirror
import { DOMParser, DOMSerializer } from "prosemirror-model"

function docToHTML(doc) {
  const div = document.createElement("div")
  const fragment = DOMSerializer.fromSchema(schema).serializeFragment(doc.content)
  div.appendChild(fragment)
  return div.innerHTML
}

// Connects to data-controller="prosemirror"
export default class extends Controller {
  static targets = ["editor", "toolbar"]

  connect() {
    this.hiddenInput =
      this.element.querySelector('input[type="hidden"]') ||
      this.element.previousElementSibling

    const editorElement = this.hasEditorTarget ? this.editorTarget : this.element

    const initialDoc = this.hiddenInput.value
      ? DOMParser.fromSchema(schema).parse(
          Object.assign(document.createElement("div"), {
            innerHTML: this.hiddenInput.value,
          })
        )
      : schema.nodes.doc.createAndFill()

    const state = EditorState.create({
      doc: initialDoc,
      plugins: [history(), buildKeymap()],
    })

    this.view = new EditorView(editorElement, {
      state,
      dispatchTransaction: (tr) => {
        const newState = this.view.state.apply(tr)
        this.view.updateState(newState)
        if (tr.docChanged) {
          this.hiddenInput.value = docToHTML(newState.doc)
          editorElement.dispatchEvent(new Event("input", { bubbles: true }))
        }
        this.updateActiveStates(newState)
      },
    })
  }

  updateActiveStates(state) {
    if (!this.hasToolbarTarget) return
    const { from, $from, to, empty } = state.selection
    const buttons = this.toolbarTarget.querySelectorAll("button[data-mark]")
    buttons.forEach((button) => {
      const markName = button.dataset.mark
      const mark = schema.marks[markName]
      if (!mark) return
      const active = empty
        ? !!mark.isInSet(state.storedMarks || $from.marks())
        : state.doc.rangeHasMark(from, to, mark)
      button.classList.toggle("bg-gray-200", active)
    })
  }

  toggleBold(event) {
    event.preventDefault()
    toggleMark(boldMark)(this.view.state, this.view.dispatch)
    this.view.focus()
  }

  setRuby(event) {
    event.preventDefault()
    const rubyMarkType = schema.marks.ruby
    const { from, to, empty } = this.view.state.selection

    if (empty) return

    // Check if selection already has ruby mark
    const hasRuby = this.view.state.doc.rangeHasMark(from, to, rubyMarkType)
    if (hasRuby) {
      const tr = this.view.state.tr.removeMark(from, to, rubyMarkType)
      this.view.dispatch(tr)
      this.view.focus()
      return
    }

    const reading = prompt("ふりがな（ルビ）を入力してください:")
    const normalizedReading = reading?.trim()
    if (!normalizedReading) return

    const tr = this.view.state.tr.addMark(
      from,
      to,
      rubyMarkType.create({ reading: normalizedReading })
    )
    this.view.dispatch(tr)
    this.view.focus()
  }

  disconnect() {
    if (this.view) {
      this.view.destroy()
    }
  }
}
