import { Controller } from "@hotwired/stimulus"
import { DOMParser, DOMSerializer, Schema } from "prosemirror-model"
import { schema as basicSchema } from "prosemirror-schema-basic"
import { EditorState } from "prosemirror-state"
import { EditorView } from "prosemirror-view"
import { history, undo, redo } from "prosemirror-history"
import { keymap } from "prosemirror-keymap"
import { toggleMark, baseKeymap } from "prosemirror-commands"
import { MenuItem, menuBar } from "prosemirror-menu"
import { rubyMark } from "../prosemirror_ruby_mark"

// Build schema: paragraph + text + bold mark + ruby mark
const schema = new Schema({
  nodes: basicSchema.spec.nodes,
  marks: basicSchema.spec.marks.append({ ruby: rubyMark }),
})

const boldMark = schema.marks.strong
const rubyMarkType = schema.marks.ruby
const boldCommand = toggleMark(boldMark)

function markIsActive(state, markType) {
  const { from, to, empty, $from } = state.selection
  if (empty) {
    return !!markType.isInSet(state.storedMarks || $from.marks())
  }
  return state.doc.rangeHasMark(from, to, markType)
}

function toggleRubyMark(state, dispatch, view) {
  const { from, to, empty } = state.selection
  if (empty) return false

  if (state.doc.rangeHasMark(from, to, rubyMarkType)) {
    if (dispatch) {
      dispatch(state.tr.removeMark(from, to, rubyMarkType).scrollIntoView())
    }
    if (view) view.focus()
    return true
  }

  const reading = window.prompt("ふりがな（ルビ）を入力してください:")
  const normalizedReading = reading?.trim()
  if (!normalizedReading) return false

  if (dispatch) {
    dispatch(
      state.tr
        .addMark(from, to, rubyMarkType.create({ reading: normalizedReading }))
        .scrollIntoView()
    )
  }
  if (view) view.focus()
  return true
}

function renderMenuButton(label) {
  const button = document.createElement("button")
  button.type = "button"
  button.textContent = label
  return button
}

function buildMenuContent() {
  return [
    [
      new MenuItem({
        render: () => renderMenuButton("太字"),
        label: "太字",
        title: "太字 (Ctrl/Cmd-B)",
        class: "pm-menu-button",
        run: (state, dispatch, view) => {
          const executed = boldCommand(state, dispatch)
          if (executed && view) view.focus()
          return executed
        },
        active: (state) => markIsActive(state, boldMark),
      }),
      new MenuItem({
        render: () => renderMenuButton("ルビ"),
        label: "ルビ",
        title: "ルビを付与/解除",
        class: "pm-menu-button",
        run: toggleRubyMark,
        enable: (state) => !state.selection.empty,
        active: (state) => markIsActive(state, rubyMarkType),
      }),
    ],
  ]
}

function buildKeymap() {
  return keymap({
    ...baseKeymap,
    "Mod-z": undo,
    "Mod-y": redo,
    "Mod-Shift-z": redo,
    "Mod-b": boldCommand,
    "Mod-B": boldCommand,
  })
}

function docToHTML(doc) {
  const div = document.createElement("div")
  const fragment = DOMSerializer.fromSchema(schema).serializeFragment(doc.content)
  div.appendChild(fragment)
  return div.innerHTML
}

// Connects to data-controller="prosemirror"
export default class extends Controller {
  static targets = ["editor"]

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
      plugins: [
        history(),
        buildKeymap(),
        menuBar({ content: buildMenuContent(), floating: false }),
      ],
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
      },
    })
  }

  disconnect() {
    if (this.view) {
      this.view.destroy()
    }
  }
}
