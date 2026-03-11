import { Controller } from "@hotwired/stimulus"

const OVERLAY_ID = "ui-feedback-overlay"
const BADGE_ID = "ui-feedback-badge"
const TOAST_ID = "ui-feedback-toast"
const STYLE_KEYS = [
  "color",
  "background-color",
  "font-size",
  "font-weight",
  "line-height",
  "padding",
  "margin",
  "border",
  "border-radius",
  "display",
  "position"
]

export default class extends Controller {
  connect() {
    this.enabled = this.syncEnabledState()
    if (!this.enabled) return

    this.ensureOverlay()
    this.ensureBadge()

    this.boundMouseMove = this.handleMouseMove.bind(this)
    this.boundClick = this.handleAltClick.bind(this)
    this.boundTeardown = this.teardown.bind(this)

    document.addEventListener("mousemove", this.boundMouseMove, true)
    document.addEventListener("click", this.boundClick, true)
    document.addEventListener("turbo:before-cache", this.boundTeardown)
  }

  disconnect() {
    document.removeEventListener("mousemove", this.boundMouseMove, true)
    document.removeEventListener("click", this.boundClick, true)
    document.removeEventListener("turbo:before-cache", this.boundTeardown)
    this.teardown()
  }

  syncEnabledState() {
    const hasControllerMeta = Boolean(document.querySelector("meta[name='rails-controller']"))
    const hasActionMeta = Boolean(document.querySelector("meta[name='rails-action']"))
    return hasControllerMeta && hasActionMeta
  }

  ensureOverlay() {
    if (this.overlay) return this.overlay

    const overlay = document.createElement("div")
    overlay.id = OVERLAY_ID
    overlay.style.position = "fixed"
    overlay.style.pointerEvents = "none"
    overlay.style.zIndex = "2147483646"
    overlay.style.border = "2px solid #2563eb"
    overlay.style.background = "rgba(37, 99, 235, 0.08)"
    overlay.style.borderRadius = "4px"
    overlay.style.display = "none"
    document.body.appendChild(overlay)

    this.overlay = overlay
    return overlay
  }

  ensureBadge() {
    if (this.badge) return this.badge

    const badge = document.createElement("div")
    badge.id = BADGE_ID
    badge.textContent = "UI Feedback ON (Alt+Click)"
    badge.style.position = "fixed"
    badge.style.right = "12px"
    badge.style.bottom = "12px"
    badge.style.padding = "6px 10px"
    badge.style.borderRadius = "999px"
    badge.style.fontSize = "12px"
    badge.style.fontWeight = "700"
    badge.style.color = "#ffffff"
    badge.style.background = "#1d4ed8"
    badge.style.boxShadow = "0 6px 24px rgba(0, 0, 0, 0.2)"
    badge.style.zIndex = "2147483647"
    document.body.appendChild(badge)

    this.badge = badge
    return badge
  }

  showToast(message, isError = false) {
    const existing = document.getElementById(TOAST_ID)
    if (existing) existing.remove()

    const toast = document.createElement("div")
    toast.id = TOAST_ID
    toast.textContent = message
    toast.style.position = "fixed"
    toast.style.left = "12px"
    toast.style.bottom = "12px"
    toast.style.maxWidth = "80vw"
    toast.style.padding = "10px 12px"
    toast.style.borderRadius = "8px"
    toast.style.fontSize = "12px"
    toast.style.color = "#ffffff"
    toast.style.background = isError ? "#b91c1c" : "#111827"
    toast.style.boxShadow = "0 8px 30px rgba(0, 0, 0, 0.3)"
    toast.style.zIndex = "2147483647"

    document.body.appendChild(toast)
    window.setTimeout(() => toast.remove(), 2600)
  }

  updateOverlay(target) {
    const overlay = this.ensureOverlay()
    if (!target) {
      overlay.style.display = "none"
      return
    }

    const rect = target.getBoundingClientRect()
    overlay.style.display = "block"
    overlay.style.left = `${rect.left}px`
    overlay.style.top = `${rect.top}px`
    overlay.style.width = `${Math.max(0, rect.width)}px`
    overlay.style.height = `${Math.max(0, rect.height)}px`
  }

  closestInspectableTarget(target) {
    if (!(target instanceof Element)) return null
    if (target.id === OVERLAY_ID || target.id === BADGE_ID || target.id === TOAST_ID) return null

    return target
  }

  selectorFor(element) {
    if (!element) return ""
    if (element.id) return `#${CSS.escape(element.id)}`

    const segments = []
    let current = element

    while (current && current.nodeType === Node.ELEMENT_NODE && segments.length < 6) {
      let segment = current.tagName.toLowerCase()

      const classes = Array.from(current.classList).filter(Boolean).slice(0, 2)
      if (classes.length > 0) {
        segment += classes.map((className) => `.${CSS.escape(className)}`).join("")
      }

      const siblings = current.parentElement ? Array.from(current.parentElement.children).filter((child) => child.tagName === current.tagName) : []
      if (siblings.length > 1 && current.parentElement) {
        const index = siblings.indexOf(current) + 1
        segment += `:nth-of-type(${index})`
      }

      segments.unshift(segment)
      current = current.parentElement

      if (current && current.tagName === "BODY") break
    }

    return segments.join(" > ")
  }

  compactText(text) {
    if (!text) return ""
    return text.replace(/\s+/g, " ").trim().slice(0, 180)
  }

  extractStyles(element) {
    const computed = window.getComputedStyle(element)
    return STYLE_KEYS.reduce((result, key) => {
      result[key] = computed.getPropertyValue(key)
      return result
    }, {})
  }

  readCsrfToken() {
    const meta = document.querySelector("meta[name='csrf-token']")
    return meta ? meta.content : ""
  }

  readMetaContent(name) {
    const meta = document.querySelector(`meta[name='${name}']`)
    return meta?.content || ""
  }

  async sendFeedback(payload) {
    const response = await fetch("/dev/ui_feedbacks", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.readCsrfToken()
      },
      body: JSON.stringify(payload),
      credentials: "same-origin"
    })

    if (!response.ok) {
      throw new Error(`保存に失敗しました (${response.status})`)
    }

    return response.json()
  }

  async copyPrompt(prompt) {
    try {
      await navigator.clipboard.writeText(prompt)
      return true
    } catch (_) {
      return false
    }
  }

  buildPayload(target, request) {
    const rect = target.getBoundingClientRect()
    const payload = {
      captured_at: new Date().toISOString(),
      request,
      url: window.location.href,
      path: `${window.location.pathname}${window.location.search}`,
      page_controller: this.readMetaContent("rails-controller"),
      page_action: this.readMetaContent("rails-action"),
      selector: this.selectorFor(target),
      tag_name: target.tagName.toLowerCase(),
      element_id: target.id || "",
      classes: Array.from(target.classList),
      text: this.compactText(target.textContent),
      styles: this.extractStyles(target),
      viewport: {
        width: window.innerWidth,
        height: window.innerHeight,
        scroll_x: window.scrollX,
        scroll_y: window.scrollY
      },
      box: {
        x: rect.x,
        y: rect.y,
        width: rect.width,
        height: rect.height
      }
    }
    return payload
  }

  teardown() {
    if (this.overlay) this.overlay.style.display = "none"
    if (this.badge) this.badge.remove()
    this.badge = null
    this.activeTarget = null
  }

  async handleAltClick(event) {
    if (!this.enabled || !event.altKey) return

    const target = this.closestInspectableTarget(event.target)
    if (!target) return

    event.preventDefault()
    event.stopPropagation()

    const request = window.prompt("この要素への要望を入力してください", "ここの色を変えたい")
    if (!request) return

    const payload = this.buildPayload(target, request)
    const copied = await this.copyPrompt(payload.prompt)

    try {
      await this.sendFeedback(payload)
      this.showToast(copied ? "要望を保存してクリップボードにコピーしました" : "要望を保存しました")
    } catch (error) {
      this.showToast(error.message, true)
    }
  }

  handleMouseMove(event) {
    if (!this.enabled) return
    if (!event.altKey) return this.teardown()

    const target = this.closestInspectableTarget(event.target)
    this.activeTarget = target
    this.updateOverlay(target)
  }
}
