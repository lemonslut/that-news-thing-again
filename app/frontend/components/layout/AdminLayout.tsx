import { ReactNode } from 'react'
import { Link, usePage } from '@inertiajs/react'
import {
  Newspaper,
  BookOpen,
  Users,
  Tags,
  FolderTree,
  FileText,
  TrendingUp,
  Activity,
  LogOut,
  Menu
} from 'lucide-react'
import { cn } from '@/lib/utils'
import { PageProps } from '@/types/models'
import { Button } from '@/components/ui/button'
import { useState } from 'react'

interface NavItem {
  name: string
  href: string
  icon: ReactNode
}

const navigation: NavItem[] = [
  { name: 'Dashboard', href: '/admin', icon: <Activity className="h-4 w-4" /> },
  { name: 'Articles', href: '/admin/articles', icon: <Newspaper className="h-4 w-4" /> },
  { name: 'Stories', href: '/admin/stories', icon: <BookOpen className="h-4 w-4" /> },
  { name: 'Concepts', href: '/admin/concepts', icon: <Tags className="h-4 w-4" /> },
  { name: 'Categories', href: '/admin/categories', icon: <FolderTree className="h-4 w-4" /> },
  { name: 'Prompts', href: '/admin/prompts', icon: <FileText className="h-4 w-4" /> },
  { name: 'Trends', href: '/admin/trend_snapshots', icon: <TrendingUp className="h-4 w-4" /> },
  { name: 'Users', href: '/admin/users', icon: <Users className="h-4 w-4" /> },
]

export default function AdminLayout({ children }: { children: ReactNode }) {
  const { auth, flash } = usePage<PageProps>().props
  const [sidebarOpen, setSidebarOpen] = useState(false)

  return (
    <div className="min-h-screen bg-background">
      {/* Mobile sidebar toggle */}
      <div className="lg:hidden fixed top-0 left-0 right-0 z-40 flex items-center gap-4 border-b bg-background px-4 py-3">
        <Button variant="ghost" size="icon" onClick={() => setSidebarOpen(!sidebarOpen)}>
          <Menu className="h-5 w-5" />
        </Button>
        <span className="font-semibold">News Digest Admin</span>
      </div>

      {/* Sidebar */}
      <aside
        className={cn(
          'fixed inset-y-0 left-0 z-50 w-64 transform border-r bg-sidebar transition-transform duration-200 lg:translate-x-0',
          sidebarOpen ? 'translate-x-0' : '-translate-x-full'
        )}
      >
        <div className="flex h-16 items-center border-b px-6">
          <span className="text-lg font-semibold text-sidebar-foreground">News Digest</span>
        </div>

        <nav className="flex flex-col gap-1 p-4">
          {navigation.map((item) => (
            <Link
              key={item.name}
              href={item.href}
              className="flex items-center gap-3 rounded-md px-3 py-2 text-sm font-medium text-sidebar-foreground hover:bg-sidebar-accent hover:text-sidebar-accent-foreground transition-colors"
            >
              {item.icon}
              {item.name}
            </Link>
          ))}
        </nav>

        {/* User section at bottom */}
        <div className="absolute bottom-0 left-0 right-0 border-t p-4">
          {auth.user && (
            <div className="flex items-center gap-3">
              {auth.user.avatar_url && (
                <img
                  src={auth.user.avatar_url}
                  alt={auth.user.github_username || auth.user.email_address}
                  className="h-8 w-8 rounded-full"
                />
              )}
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium text-sidebar-foreground truncate">
                  {auth.user.github_username || auth.user.email_address}
                </p>
              </div>
              <Link href="/session" method="delete" as="button">
                <LogOut className="h-4 w-4 text-sidebar-foreground hover:text-sidebar-accent-foreground" />
              </Link>
            </div>
          )}
        </div>
      </aside>

      {/* Backdrop for mobile */}
      {sidebarOpen && (
        <div
          className="fixed inset-0 z-40 bg-black/50 lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Main content */}
      <main className="lg:pl-64 pt-14 lg:pt-0">
        <div className="p-6">
          {/* Flash messages */}
          {flash.notice && (
            <div className="mb-4 rounded-md bg-green-50 dark:bg-green-900/20 p-4 text-sm text-green-800 dark:text-green-200">
              {flash.notice}
            </div>
          )}
          {flash.alert && (
            <div className="mb-4 rounded-md bg-red-50 dark:bg-red-900/20 p-4 text-sm text-red-800 dark:text-red-200">
              {flash.alert}
            </div>
          )}

          {children}
        </div>
      </main>
    </div>
  )
}
