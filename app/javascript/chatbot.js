document.addEventListener("turbo:load", () => {
  const toggle = document.getElementById("chatbot-toggle");
  const chatWindow = document.getElementById("chatbot-window");

  if (toggle && chatWindow) {
    toggle.addEventListener("click", () => {
      chatWindow.classList.toggle("hidden");
    });
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
});
