const submitFormWithFetch = async (form) => {
  // Turbo Drive submission: just call requestSubmit, Turbo will handle fetch and stream
  if (!form) return;
  if (window.Turbo && typeof form.requestSubmit === "function") {
    form.requestSubmit();
  } else {
    form.submit();
  }
};


const setEditorState = (textarea, state) => {
  // state: "editing" | "saving" | "saved"
  if (!textarea) return;
  textarea.classList.remove("border-editing", "border-saving", "border-saved");
  if (state === "editing") {
    textarea.classList.add("border-editing");
  } else if (state === "saving") {
    textarea.classList.add("border-saving");
  } else if (state === "saved") {
    textarea.classList.add("border-saved");
  }
};

const stopEditing = async (container) => {
  if (!container) return;
  const form = container.querySelector("form");
  const textarea = form?.querySelector(".scene-textarea");
  if (form && textarea) {
    setEditorState(textarea, "saving");
    await submitFormWithFetch(form).catch(err => { console.error(err); form.requestSubmit(); });
    setEditorState(textarea, "saved");
  }
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
  setEditorState(textarea, "editing");
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

document.addEventListener("blur", (e) => {
  if (e.target === document) return;
  const textarea = e.target.closest(".scene-textarea");
  if (textarea) {
    const container = textarea.closest(".scene-container");
    if (container) {
      stopEditing(container);
    }
  }
}, true);

document.addEventListener("input", (e) => {
  if (e.target.matches(".scene-textarea")) {
    e.target.style.height = "auto";
    e.target.style.height = e.target.scrollHeight + "px";
    setEditorState(e.target, "editing");
  }
});
