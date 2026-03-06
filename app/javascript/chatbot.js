document.addEventListener("turbo:load", () => {
  const applyThinkingMessageGrouping = () => {
    const messages = document.getElementById("messages");
    if (!messages) return;

    const rows = Array.from(messages.children).filter((node) =>
      node.id?.startsWith("message_")
    );

    rows.forEach((row) => row.classList.remove("thinking-continuation"));

    let hasThinkingLeader = false;

    rows.forEach((row) => {
      if (row.dataset.messageKind !== "thinking") {
        hasThinkingLeader = false;
        return;
      }

      if (!hasThinkingLeader) {
        hasThinkingLeader = true;
        return;
      }

      row.classList.add("thinking-continuation");
    });
  };

  const attachThinkingMessageObserver = () => {
    const messages = document.getElementById("messages");
    if (!messages || messages.dataset.thinkingObserverAttached === "true") return;

    const observer = new MutationObserver(() => {
      applyThinkingMessageGrouping();
    });

    observer.observe(messages, { childList: true, subtree: true });
    messages.dataset.thinkingObserverAttached = "true";
  };

  const toggle = document.getElementById("chatbot-toggle");
  const chatWindow = document.getElementById("chatbot-window");
  const wrapper = document.getElementById("chatbot-wrapper");

  if (toggle && chatWindow) {
    toggle.addEventListener("click", () => {
      chatWindow.classList.toggle("hidden");
    });
  }

  if (chatWindow && wrapper?.dataset.autoOpen === "true") {
    chatWindow.classList.remove("hidden");
  }

  window.addEventListener("message", (event) => {
    if (event.origin !== window.location.origin) return;
    if (event.data === "close-chat") {
      if (chatWindow) chatWindow.classList.add("hidden");
    }
  });

  if (!window.chatChoiceHandler) {
    window.chatChoiceHandler = (event) => {
      const button = event.target.closest(".chat-choice-btn");
      if (!button) return;

      const value = button.dataset.choice;
      const form = document.getElementById("new_message");
      if (!form) return;

      const input = form.querySelector('input[name="message[content]"]');
      if (!input) return;

      input.value = value || "";
      form.requestSubmit();
    };

    document.addEventListener("click", window.chatChoiceHandler);
  }

  applyThinkingMessageGrouping();
  attachThinkingMessageObserver();
});
