import { defineConfig } from "vite";
import { VitePWA } from "vite-plugin-pwa";

export default defineConfig({
  build: {
    // Rails serves /assets/ itself once the Service Worker is active, so the launcher's bundled
    // files live under a prefix the worker passes through to the network (see rails.sw.js).
    assetsDir: "pwa-assets",
    rollupOptions: {
      input: {
        main: new URL("index.html", import.meta.url).pathname,
        boot: new URL("boot.html", import.meta.url).pathname,
      },
    },
  },
  optimizeDeps: {
    exclude: ["@sqlite.org/sqlite-wasm"],
  },
  plugins: [
    VitePWA({
      srcDir: ".",
      filename: "rails.sw.js",
      strategies: "injectManifest",
      injectRegister: false,
      manifest: false,
      injectManifest: {
        injectionPoint: null,
      },
      devOptions: {
        enabled: true,
        type: "module",
      },
    }),
  ],
});
