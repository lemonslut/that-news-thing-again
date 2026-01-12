import { useForm, usePage } from '@inertiajs/react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { PageProps } from '@/types/models'

export default function Login() {
  const { flash } = usePage<PageProps>().props
  const { data, setData, post, processing, errors } = useForm({
    email_address: '',
    password: ''
  })

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    post('/session')
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-background p-4">
      <Card className="w-full max-w-md">
        <CardHeader className="text-center">
          <CardTitle className="text-2xl">News Digest Admin</CardTitle>
          <CardDescription>Sign in to continue</CardDescription>
        </CardHeader>
        <CardContent>
          {flash.alert && (
            <div className="mb-4 rounded-md bg-red-50 dark:bg-red-900/20 p-4 text-sm text-red-800 dark:text-red-200">
              {flash.alert}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="email_address">Email</Label>
              <Input
                id="email_address"
                type="email"
                value={data.email_address}
                onChange={(e) => setData('email_address', e.target.value)}
                placeholder="you@example.com"
                autoComplete="email"
                autoFocus
              />
              {errors.email_address && (
                <p className="text-sm text-destructive">{errors.email_address}</p>
              )}
            </div>

            <div className="space-y-2">
              <Label htmlFor="password">Password</Label>
              <Input
                id="password"
                type="password"
                value={data.password}
                onChange={(e) => setData('password', e.target.value)}
                autoComplete="current-password"
              />
              {errors.password && (
                <p className="text-sm text-destructive">{errors.password}</p>
              )}
            </div>

            <Button type="submit" className="w-full" disabled={processing}>
              {processing ? 'Signing in...' : 'Sign in'}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  )
}

// Don't use AdminLayout for login page
Login.layout = (page: React.ReactNode) => page
