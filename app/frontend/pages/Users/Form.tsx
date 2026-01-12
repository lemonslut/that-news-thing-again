import { useForm, Link } from '@inertiajs/react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { ArrowLeft } from 'lucide-react'

interface UserFormProps {
  user: {
    id: number
    email_address: string
    allowed: boolean
  }
}

export default function UserForm({ user }: UserFormProps) {
  const { data, setData, put, processing, errors } = useForm({
    email_address: user.email_address,
    allowed: user.allowed
  })

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    put(`/admin/users/${user.id}`)
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="icon" asChild>
          <Link href={`/admin/users/${user.id}`}>
            <ArrowLeft className="h-4 w-4" />
          </Link>
        </Button>
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Edit User</h1>
        </div>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>User Details</CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="email_address">Email</Label>
              <Input
                id="email_address"
                type="email"
                value={data.email_address}
                onChange={(e) => setData('email_address', e.target.value)}
              />
              {errors.email_address && <p className="text-sm text-destructive">{errors.email_address}</p>}
            </div>

            <div className="flex items-center gap-2">
              <input
                type="checkbox"
                id="allowed"
                checked={data.allowed}
                onChange={(e) => setData('allowed', e.target.checked)}
                className="h-4 w-4 rounded border-input"
              />
              <Label htmlFor="allowed">Allowed to access admin</Label>
            </div>

            <div className="flex gap-2">
              <Button type="submit" disabled={processing}>
                {processing ? 'Saving...' : 'Save Changes'}
              </Button>
              <Button variant="outline" asChild>
                <Link href={`/admin/users/${user.id}`}>Cancel</Link>
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  )
}
