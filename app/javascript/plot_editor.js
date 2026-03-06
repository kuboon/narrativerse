const submitFormWithFetch = async (form) => {
  if (!form) return;

  if (window.Turbo && typeof form.requestSubmit === "function") {
    form.requestSubmit();
  } else {
    form.submit();
  }
};

const setEditorState = (hiddenInput, state) => {
  if (!hiddenInput) return;

  hiddenInput.classList.remove("border-editing", "border-saving", "border-saved");
  if (state === "editing") {
    hiddenInput.classList.add("border-editing");
  } else if (state === "saving") {
    hiddenInput.classList.add("border-saving");
  } else if (state === "saved") {
    hiddenInput.classList.add("border-saved");
  }
};

let activeContainer = null;

const stopEditing = async (container) => {
  if (!container) return;

  const form = container.querySelector(".plot-form");
  const hiddenInputs = Array.from(form?.querySelectorAll(".plot-textarea") || []);

  hiddenInputs.forEach((input) => setEditorState(input, "saving"));
  try {
    await submitFormWithFetch(form);
    hiddenInputs.forEach((input) => setEditorState(input, "saved"));
  } catch (error) {
    console.error(error);
    form?.requestSubmit();
  }

  container.querySelector(".plot-display")?.classList.remove("hidden");
  container.querySelector(".plot-editor")?.classList.add("hidden");

  if (activeContainer === container) {
    activeContainer = null;
  }
};

const startEditing = async (container) => {
  if (!container) return;

  if (activeContainer && activeContainer !== container) {
    await stopEditing(activeContainer);
  }

  const editor = container.querySelector(".plot-editor");
  if (!editor) return;

  container.querySelector(".plot-display")?.classList.add("hidden");
  editor.classList.remove("hidden");

  const hiddenInputs = Array.from(editor.querySelectorAll(".plot-textarea"));
  hiddenInputs.forEach((input) => setEditorState(input, "editing"));

  editor.querySelector(".ProseMirror")?.focus();
  activeContainer = container;
};

const clickedInteractiveElement = (target) => {
  return !!target.closest("a, button, summary, input, textarea, select, label, .pm-menu-button");
};

document.addEventListener("click", (event) => {
  const display = event.target.closest(".plot-display");

  if (display && !clickedInteractiveElement(event.target)) {
    const container = display.closest(".plot-container");
    if (container) {
      startEditing(container);
      return;
    }
  }

  if (activeContainer && !event.target.closest(".plot-container")) {
    stopEditing(activeContainer);
  }
});

document.addEventListener("input", (event) => {
  const editorElement = event.target.closest(".prosemirror-editor");
  if (!editorElement) return;

  const hiddenInput = editorElement.previousElementSibling;
  if (hiddenInput && hiddenInput.classList.contains("plot-textarea")) {
    setEditorState(hiddenInput, "editing");
  }
});

document.addEventListener("keydown", (event) => {
  if (event.key !== "Escape" || !activeContainer) return;

  activeContainer.querySelector(".plot-display")?.classList.remove("hidden");
  activeContainer.querySelector(".plot-editor")?.classList.add("hidden");
  activeContainer = null;
});

document.addEventListener("turbo:before-cache", () => {
  if (!activeContainer) return;

  activeContainer.querySelector(".plot-display")?.classList.remove("hidden");
  activeContainer.querySelector(".plot-editor")?.classList.add("hidden");
  activeContainer = null;
});
