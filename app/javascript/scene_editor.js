const submitFormWithFetch = async (form) => {
  const action = form.action;
  const method = (form.method || "post").toUpperCase();

  const tokenMeta = document.querySelector('meta[name="csrf-token"]');
  const csrfToken = tokenMeta ? tokenMeta.content : null;

  const formData = new FormData(form);
  const body = new URLSearchParams();
  for (const pair of formData.entries()) { body.append(pair[0], pair[1]); }

  const resp = await fetch(action, {
    method: method === "POST" ? "POST" : method,
    credentials: "same-origin",
    headers: Object.assign({ "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" }, csrfToken ? { "X-CSRF-Token": csrfToken } : {}),
    body: body.toString()
  });

  const contentType = resp.headers.get("content-type") || "";
  const text = await resp.text();

  if (contentType.includes("text/vnd.turbo-stream")) {
    if (window.Turbo && typeof Turbo.renderStreamMessage === "function") {
      Turbo.renderStreamMessage(text);
    } else {
      const parser = new DOMParser();
      const doc = parser.parseFromString(text, "text/html");
      const replacement = doc.body.firstElementChild;
      const id = replacement && replacement.id;
      if (id) {
        const old = document.getElementById(id);
        if (old && replacement) old.replaceWith(replacement);
      }
    }
  } else if (resp.redirected) {
    window.location = resp.url;
  }
};

const stopEditing = (container) => {
  if (!container) return;
  const form = container.querySelector("form");
  if (form) submitFormWithFetch(form).catch(err => { console.error(err); form.requestSubmit(); });
  container.querySelector(".scene-display").classList.remove("hidden");
  const editor = container.querySelector(".scene-editor");
  if (editor) editor.classList.add("hidden");
};

const stopAllEditors = () => {
  document.querySelectorAll(".scene-container").forEach(container => {
    const editor = container.querySelector(".scene-editor");
    if (editor && !editor.classList.contains("hidden")) {
      stopEditing(container);
    }
  });
};

const startEditing = (container) => {
  stopAllEditors();
  const editor = container.querySelector(".scene-editor");
  if (!editor) return;
  container.querySelector(".scene-display").classList.add("hidden");
  editor.classList.remove("hidden");
  const textarea = editor.querySelector("textarea");
  textarea.focus();
  textarea.style.height = "auto";
  textarea.style.height = textarea.scrollHeight + "px";
};

document.addEventListener("click", (e) => {
  const display = e.target.closest(".scene-display");
  if (display) {
    const container = display.closest(".scene-container");
    if (container) startEditing(container);
  }
});

document.addEventListener("focusout", (e) => {
  const container = e.target.closest(".scene-container");
  if (container) {
    setTimeout(() => {
      if (!container.contains(document.activeElement)) {
        const editor = container.querySelector(".scene-editor");
        if (editor && !editor.classList.contains("hidden")) {
          stopEditing(container);
        }
      }
    }, 0);
  }
});

document.addEventListener("input", (e) => {
  if (e.target.matches(".scene-textarea")) {
    e.target.style.height = "auto";
    e.target.style.height = e.target.scrollHeight + "px";
  }
});
