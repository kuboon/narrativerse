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

function buildKeymap(controller) {
  return keymap({
    ...baseKeymap,
    "Mod-z": undo,
    "Mod-y": redo,
    "Mod-Shift-z": redo,
    "Mod-b": boldCommand,
    "Mod-B": boldCommand,
    Escape: () => {
      controller.cancel()
      return true
    },
  })
}

function docToHTML(doc) {
  const div = document.createElement("div")
  const fragment = DOMSerializer.fromSchema(schema).serializeFragment(doc.content)
  div.appendChild(fragment)
  return div.innerHTML
}

function docFromHTML(html) {
  if (html?.trim()) {
    const container = document.createElement("div")
    container.innerHTML = html
    return DOMParser.fromSchema(schema).parse(container)
  }

  return schema.nodes.doc.createAndFill()
}

export default class extends Controller {
  static values = {
    url: String,
    param: { type: String, default: "scene[text]" },
    method: { type: String, default: "patch" },
    placeholder: { type: String, default: "" },
    initialHtml: String,
  }

  connect() {
    this.isEditing = false
    this.isSaving = false
    this.savedHtml = this.hasInitialHtmlValue ? this.initialHtmlValue : this.element.innerHTML.trim()

    this.boundStartEdit = this.startEdit.bind(this)
    this.boundCloseOthers = this.closeOthers.bind(this)
    this.boundBeforeCache = this.beforeCache.bind(this)

    this.element.addEventListener("click", this.boundStartEdit)
    window.addEventListener("inline-prosemirror:close-others", this.boundCloseOthers)
    document.addEventListener("turbo:before-cache", this.boundBeforeCache)

    this.renderDisplay()
  }

  disconnect() {
    this.element.removeEventListener("click", this.boundStartEdit)
    window.removeEventListener("inline-prosemirror:close-others", this.boundCloseOthers)
    document.removeEventListener("turbo:before-cache", this.boundBeforeCache)

    this.teardownEditor()
  }

  startEdit(event) {
    if (!this.hasUrlValue || this.isEditing || this.isSaving) return
    if (this.clickedInteractiveElement(event.target)) return

    this.stopAllOtherEditors()
    this.openEditor()
  }

  openEditor() {
    if (this.isEditing) return

    this.isEditing = true
    this.element.innerHTML = ""

    this.editorWrapper = document.createElement("div")
    this.editorWrapper.className = "prosemirror-editor-container"

    const editorDiv = document.createElement("div")
    editorDiv.className = "prosemirror-editor w-full min-h-25"
    this.editorWrapper.appendChild(editorDiv)

    this.form = this.buildForm()
    this.input = this.form.querySelector("input[type='hidden'][name]:last-of-type")

    this.element.appendChild(this.editorWrapper)
    this.element.appendChild(this.form)

    const state = EditorState.create({
      doc: docFromHTML(this.savedHtml),
      plugins: [
        history(),
        buildKeymap(this),
        menuBar({ content: buildMenuContent(), floating: false }),
      ],
    })

    this.view = new EditorView(editorDiv, {
      state,
      dispatchTransaction: (tr) => {
        const newState = this.view.state.apply(tr)
        this.view.updateState(newState)

        if (tr.docChanged && this.input) {
          this.input.value = docToHTML(newState.doc)
        }
      },
      handleDOMEvents: {
        focusout: () => {
          this.scheduleBlurSave()
          return false
        },
      },
    })

    if (this.input) {
      this.input.value = docToHTML(this.view.state.doc)
    }

    this.view.focus()
  }

  scheduleBlurSave() {
    requestAnimationFrame(() => {
      if (!this.isEditing || this.isSaving) return
      if (this.element.contains(document.activeElement)) return
      this.save()
    })
  }

  save() {
    if (!this.isEditing || this.isSaving) return

    this.isSaving = true
    this.savedHtml = docToHTML(this.view.state.doc)
    if (this.input) {
      this.input.value = this.savedHtml
    }

    if (this.form) {
      if (window.Turbo && typeof this.form.requestSubmit === "function") {
        this.form.requestSubmit()
      } else {
        this.form.submit()
      }
    }

    this.isSaving = false
    this.teardownEditor()
    this.renderDisplay()
  }

  cancel() {
    if (!this.isEditing || this.isSaving) return
    this.teardownEditor()
    this.renderDisplay()
  }

  closeOthers(event) {
    if (event.detail.controller !== this && this.isEditing) {
      this.save()
    }
  }

  beforeCache() {
    if (this.isEditing) {
      this.cancel()
    }
  }

  stopAllOtherEditors() {
    const event = new CustomEvent("inline-prosemirror:close-others", { detail: { controller: this } })
    window.dispatchEvent(event)
  }

  buildForm() {
    const form = document.createElement("form")
    form.action = this.urlValue
    form.method = "post"
    form.className = "hidden"

    const method = this.methodValue.toLowerCase()
    if (method !== "post") {
      const methodInput = document.createElement("input")
      methodInput.type = "hidden"
      methodInput.name = "_method"
      methodInput.value = method
      form.appendChild(methodInput)
    }

    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
    if (csrfToken) {
      const csrfInput = document.createElement("input")
      csrfInput.type = "hidden"
      csrfInput.name = "authenticity_token"
      csrfInput.value = csrfToken
      form.appendChild(csrfInput)
    }

    const input = document.createElement("input")
    input.type = "hidden"
    input.name = this.paramValue
    input.value = this.savedHtml
    form.appendChild(input)

    return form
  }

  renderDisplay() {
    const normalized = this.savedHtml.trim()
    if (normalized) {
      this.element.innerHTML = normalized
    } else {
      this.element.textContent = this.placeholderValue
    }
  }

  teardownEditor() {
    if (this.view) {
      this.view.destroy()
      this.view = null
    }

    if (this.editorWrapper) {
      this.editorWrapper.remove()
      this.editorWrapper = null
    }

    if (this.form) {
      this.form.remove()
      this.form = null
    }

    this.input = null
    this.isEditing = false
  }

  clickedInteractiveElement(target) {
    return !!target.closest("a, button, summary, input, textarea, select, label, .pm-menu-button")
  }
}
