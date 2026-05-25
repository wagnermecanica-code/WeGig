import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  base: '/admin/',
  server: {
    port: 3001,
    host: true,
    // Em dev, simula o base path /admin/
    // Acesse http://localhost:3001/admin/ durante o desenvolvimento
  },
});
