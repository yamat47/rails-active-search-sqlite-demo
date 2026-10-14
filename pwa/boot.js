// Registers the Service Worker that runs Rails, shows what it is doing while it installs, and
// moves on to the application once it is ready. Based on the launcher wasmify-rails generates.
const workerUrl = import.meta.env.MODE === "production" ? "/rails.sw.js" : "/dev-sw.js?dev-sw";

async function registerServiceWorker(onFailure) {
  for (const registration of await navigator.serviceWorker.getRegistrations()) {
    if (registration.installing?.state === "installing") return;
  }
  const registration = await navigator.serviceWorker.register(workerUrl, { scope: "/", type: "module" });
  // An install that throws ends as "redundant" and `ready` never resolves; report it instead.
  registration.installing?.addEventListener("statechange", (event) => {
    if (event.target.state === "redundant") onFailure();
  });
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
    await registerServiceWorker(() => {
      output.textContent += "The Service Worker failed to install. The messages above say where it stopped; Reset and reload to try again.\n";
      progress.removeAttribute("value");
    });
  }

  await navigator.serviceWorker.ready;
  progress.value = 100;
  message.textContent = "Ready. Opening the application...";
  window.location.replace("/");
}

init();
