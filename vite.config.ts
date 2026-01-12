import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  base: '/vite/',
  root: path.resolve(__dirname, 'app/frontend'),
  publicDir: path.resolve(__dirname, 'public'),
  build: {
    manifest: true,
    outDir: path.resolve(__dirname, 'public/vite'),
    emptyOutDir: true,
    rollupOptions: {
      input: {
        application: path.resolve(__dirname, 'app/frontend/application.tsx')
      }
    }
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './app/frontend'),
      '@components': path.resolve(__dirname, './app/frontend/components'),
      '@pages': path.resolve(__dirname, './app/frontend/pages'),
      '@lib': path.resolve(__dirname, './app/frontend/lib')
    }
  },
  server: {
    port: 3036,
    strictPort: true,
    origin: 'http://localhost:3036',
    hmr: {
      host: 'localhost'
    }
  }
})
