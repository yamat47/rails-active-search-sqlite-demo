// Registers the Service Worker that runs Rails, shows what it is doing while it installs, and
// moves on to the application once it is ready. Based on the launcher wasmify-rails generates.
const workerUrl = import.meta.env.MODE === "production" ? "/rails.sw.js" : "/dev-sw.js?dev-sw";

async function registerServiceWorker() {
  for (const registration of await navigator.serviceWorker.getRegistrations()) {
    if (registration.installing?.state === "installing") return;
  }
  await navigator.serviceWorker.register(workerUrl, { scope: "/", type: "module" });
}

async function resetServiceWorker() {
  for (const registration of await navigator.serviceWorker.getRegistrations()) {
    await registration.unregister();
  }
  window.location.reload();
}

async function init() {
  const message = document.getElementById("boot-message");
  const progress = document.getElementById("boot-progress");
  const output = document.getElementById("boot-console-output");

  document.getElementById("reset-button").addEventListener("click", resetServiceWorker);

  if (!("serviceWorker" in navigator)) {
    message.textContent = "This browser has no Service Worker support, which the demo needs.";
    return;
  }

  navigator.serviceWorker.addEventListener("message", (event) => {
    switch (event.data.type) {
      case "progress":
        message.textContent = event.data.step;
        progress.value = event.data.value;
        break;
      case "console":
        output.textContent += event.data.message + "\n";
        output.scrollTop = output.scrollHeight;
        break;
    }
  });

  if (!navigator.serviceWorker.controller) {
    message.textContent = "Installing...";
    await registerServiceWorker();
  }

  await navigator.serviceWorker.ready;
  progress.value = 100;
  message.textContent = "Ready. Opening the application...";
  window.location.replace("/");
}

init();
