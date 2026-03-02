document.addEventListener("turbo:load", () => {
  const toggle = document.getElementById("chatbot-toggle");
  const chatWindow = document.getElementById("chatbot-window");

  if (toggle && chatWindow) {
    toggle.addEventListener("click", () => {
      if (chatWindow.style.display === "none") {
        chatWindow.style.display = "flex";
      } else {
        chatWindow.style.display = "none";
      }
    });
  }

  window.addEventListener("message", (event) => {
    if (event.origin !== window.location.origin) return;
    if (event.data === "close-chat") {
      if (chatWindow) chatWindow.style.display = "none";
    }
  });
});
