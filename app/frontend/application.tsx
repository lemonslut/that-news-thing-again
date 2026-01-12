import { createRoot } from 'react-dom/client'
import { createInertiaApp } from '@inertiajs/react'
import AdminLayout from '@/components/layout/AdminLayout'
import './styles/application.css'

createInertiaApp({
  resolve: name => {
    const pages = import.meta.glob('./pages/**/*.tsx', { eager: true }) as Record<string, { default: React.ComponentType & { layout?: (page: React.ReactNode) => React.ReactNode } }>
    const page = pages[`./pages/${name}.tsx`]

    if (!page) {
      throw new Error(`Page not found: ${name}`)
    }

    // Apply AdminLayout to all pages except Auth
    if (!name.startsWith('Auth/')) {
      page.default.layout = page.default.layout || ((pageContent: React.ReactNode) => <AdminLayout>{pageContent}</AdminLayout>)
    }

    return page
  },
  setup({ el, App, props }) {
    createRoot(el).render(<App {...props} />)
  }
})
