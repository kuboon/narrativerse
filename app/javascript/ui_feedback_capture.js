const OVERLAY_ID = "ui-feedback-overlay";
const BADGE_ID = "ui-feedback-badge";
const TOAST_ID = "ui-feedback-toast";
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
];

const state = {
  enabled: false,
  overlay: null,
  badge: null,
  activeTarget: null,
  initialized: false
};

function syncEnabledState() {
  const hasControllerMeta = Boolean(document.querySelector("meta[name='rails-controller']"));
  const hasActionMeta = Boolean(document.querySelector("meta[name='rails-action']"));
  return hasControllerMeta && hasActionMeta;
}

function ensureOverlay() {
  if (state.overlay) return state.overlay;

  const overlay = document.createElement("div");
  overlay.id = OVERLAY_ID;
  overlay.style.position = "fixed";
  overlay.style.pointerEvents = "none";
  overlay.style.zIndex = "2147483646";
  overlay.style.border = "2px solid #2563eb";
  overlay.style.background = "rgba(37, 99, 235, 0.08)";
  overlay.style.borderRadius = "4px";
  overlay.style.display = "none";
  document.body.appendChild(overlay);

  state.overlay = overlay;
  return overlay;
}

function ensureBadge() {
  if (state.badge) return state.badge;

  const badge = document.createElement("div");
  badge.id = BADGE_ID;
  badge.textContent = "UI Feedback ON (Alt+Click)";
  badge.style.position = "fixed";
  badge.style.right = "12px";
  badge.style.bottom = "12px";
  badge.style.padding = "6px 10px";
  badge.style.borderRadius = "999px";
  badge.style.fontSize = "12px";
  badge.style.fontWeight = "700";
  badge.style.color = "#ffffff";
  badge.style.background = "#1d4ed8";
  badge.style.boxShadow = "0 6px 24px rgba(0, 0, 0, 0.2)";
  badge.style.zIndex = "2147483647";
  document.body.appendChild(badge);

  state.badge = badge;
  return badge;
}

function showToast(message, isError = false) {
  const existing = document.getElementById(TOAST_ID);
  if (existing) existing.remove();

  const toast = document.createElement("div");
  toast.id = TOAST_ID;
  toast.textContent = message;
  toast.style.position = "fixed";
  toast.style.left = "12px";
  toast.style.bottom = "12px";
  toast.style.maxWidth = "80vw";
  toast.style.padding = "10px 12px";
  toast.style.borderRadius = "8px";
  toast.style.fontSize = "12px";
  toast.style.color = "#ffffff";
  toast.style.background = isError ? "#b91c1c" : "#111827";
  toast.style.boxShadow = "0 8px 30px rgba(0, 0, 0, 0.3)";
  toast.style.zIndex = "2147483647";

  document.body.appendChild(toast);
  window.setTimeout(() => toast.remove(), 2600);
}

function updateOverlay(target) {
  const overlay = ensureOverlay();
  if (!target) {
    overlay.style.display = "none";
    return;
  }

  const rect = target.getBoundingClientRect();
  overlay.style.display = "block";
  overlay.style.left = `${rect.left}px`;
  overlay.style.top = `${rect.top}px`;
  overlay.style.width = `${Math.max(0, rect.width)}px`;
  overlay.style.height = `${Math.max(0, rect.height)}px`;
}

function closestInspectableTarget(target) {
  if (!(target instanceof Element)) return null;
  if (target.id === OVERLAY_ID || target.id === BADGE_ID || target.id === TOAST_ID) return null;

  return target;
}

function selectorFor(element) {
  if (!element) return "";
  if (element.id) return `#${CSS.escape(element.id)}`;

  const segments = [];
  let current = element;

  while (current && current.nodeType === Node.ELEMENT_NODE && segments.length < 6) {
    let segment = current.tagName.toLowerCase();

    const classes = Array.from(current.classList).filter(Boolean).slice(0, 2);
    if (classes.length > 0) {
      segment += classes.map((className) => `.${CSS.escape(className)}`).join("");
    }

    const siblings = current.parentElement ? Array.from(current.parentElement.children).filter((child) => child.tagName === current.tagName) : [];
    if (siblings.length > 1 && current.parentElement) {
      const index = siblings.indexOf(current) + 1;
      segment += `:nth-of-type(${index})`;
    }

    segments.unshift(segment);
    current = current.parentElement;

    if (current && current.tagName === "BODY") break;
  }

  return segments.join(" > ");
}

function compactText(text) {
  if (!text) return "";
  return text.replace(/\s+/g, " ").trim().slice(0, 180);
}

function extractStyles(element) {
  const computed = window.getComputedStyle(element);
  return STYLE_KEYS.reduce((result, key) => {
    result[key] = computed.getPropertyValue(key);
    return result;
  }, {});
}

function buildPrompt(payload) {
  const styleLines = Object.entries(payload.styles)
    .map(([key, value]) => `- ${key}: ${value}`)
    .join("\n");

  return [
    "UI修正要望です。以下の要素を修正してください。",
    `要望: ${payload.request}`,
    `URL: ${payload.url}`,
    `controller: ${payload.page_controller || "(不明)"}`,
    `action: ${payload.page_action || "(不明)"}`,
    `selector: ${payload.selector}`,
    `tag: ${payload.tag_name}`,
    `text: ${payload.text || "(空)"}`,
    "現在のスタイル:",
    styleLines,
    "最小変更で実装し、必要なら該当CSS/テンプレートも更新してください。"
  ].join("\n");
}

function readCsrfToken() {
  const meta = document.querySelector("meta[name='csrf-token']");
  return meta ? meta.content : "";
}

function readMetaContent(name) {
  const meta = document.querySelector(`meta[name='${name}']`);
  return meta?.content || "";
}

async function sendFeedback(payload) {
  const response = await fetch("/dev/ui_feedbacks", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-CSRF-Token": readCsrfToken()
    },
    body: JSON.stringify(payload),
    credentials: "same-origin"
  });

  if (!response.ok) {
    throw new Error(`保存に失敗しました (${response.status})`);
  }

  return response.json();
}

async function copyPrompt(prompt) {
  try {
    await navigator.clipboard.writeText(prompt);
    return true;
  } catch (_) {
    return false;
  }
}

function buildPayload(target, request) {
  const rect = target.getBoundingClientRect();
  const payload = {
    captured_at: new Date().toISOString(),
    request,
    url: window.location.href,
    path: `${window.location.pathname}${window.location.search}`,
    page_controller: readMetaContent("rails-controller"),
    page_action: readMetaContent("rails-action"),
    selector: selectorFor(target),
    tag_name: target.tagName.toLowerCase(),
    element_id: target.id || "",
    classes: Array.from(target.classList),
    text: compactText(target.textContent),
    styles: extractStyles(target),
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
  };

  payload.prompt = buildPrompt(payload);
  return payload;
}

function teardown() {
  if (state.overlay) state.overlay.style.display = "none";
  if (state.badge) state.badge.remove();
  state.badge = null;
  state.activeTarget = null;
}

async function handleAltClick(event) {
  if (!state.enabled || !event.altKey) return;

  const target = closestInspectableTarget(event.target);
  if (!target) return;

  event.preventDefault();
  event.stopPropagation();

  const request = window.prompt("この要素への要望を入力してください", "ここの色を変えたい");
  if (!request) return;

  const payload = buildPayload(target, request);

  const copied = await copyPrompt(payload.prompt);

  try {
    await sendFeedback(payload);
    showToast(copied ? "要望を保存してクリップボードにコピーしました" : "要望を保存しました");
  } catch (error) {
    showToast(error.message, true);
  }
}

function handleMouseMove(event) {
  if (!state.enabled) return;
  if (!event.altKey) return teardown();

  const target = closestInspectableTarget(event.target);
  state.activeTarget = target;
  updateOverlay(target);
}

function initialize() {
  state.enabled = syncEnabledState();

  if (!state.enabled) {
    teardown();
    return;
  }

  ensureOverlay();
  ensureBadge();
}

function attachEventsOnce() {
  if (state.initialized) return;

  document.addEventListener("mousemove", handleMouseMove, true);
  document.addEventListener("click", handleAltClick, true);
  document.addEventListener("turbo:before-cache", teardown);
  state.initialized = true;
}

document.addEventListener("turbo:load", () => {
  attachEventsOnce();
  initialize();
});
