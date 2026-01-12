import { Link, router } from '@inertiajs/react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { ArrowLeft, Pencil, Trash, CheckCircle, XCircle } from 'lucide-react'
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from '@/components/ui/alert-dialog'

interface UserShowProps {
  user: {
    id: number
    email_address: string
    github_username?: string
    avatar_url?: string
    provider: string
    allowed: boolean
    api_token?: string
    sessions_count: number
    created_at: string
  }
}

export default function UserShow({ user }: UserShowProps) {
  const handleDelete = () => {
    router.delete(`/admin/users/${user.id}`)
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Button variant="ghost" size="icon" asChild>
            <Link href="/admin/users">
              <ArrowLeft className="h-4 w-4" />
            </Link>
          </Button>
          <div className="flex items-center gap-4">
            {user.avatar_url && (
              <img src={user.avatar_url} alt="" className="h-12 w-12 rounded-full" />
            )}
            <div>
              <h1 className="text-2xl font-bold tracking-tight">
                {user.github_username || user.email_address}
              </h1>
              {user.github_username && (
                <p className="text-muted-foreground">{user.email_address}</p>
              )}
            </div>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline" size="sm" asChild>
            <Link href={`/admin/users/${user.id}/edit`}>
              <Pencil className="h-4 w-4 mr-2" />
              Edit
            </Link>
          </Button>
          <AlertDialog>
            <AlertDialogTrigger asChild>
              <Button variant="destructive" size="sm">
                <Trash className="h-4 w-4 mr-2" />
                Delete
              </Button>
            </AlertDialogTrigger>
            <AlertDialogContent>
              <AlertDialogHeader>
                <AlertDialogTitle>Delete User</AlertDialogTitle>
                <AlertDialogDescription>
                  Are you sure? This will delete all their sessions.
                </AlertDialogDescription>
              </AlertDialogHeader>
              <AlertDialogFooter>
                <AlertDialogCancel>Cancel</AlertDialogCancel>
                <AlertDialogAction onClick={handleDelete}>Delete</AlertDialogAction>
              </AlertDialogFooter>
            </AlertDialogContent>
          </AlertDialog>
        </div>
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Details</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex justify-between">
              <span className="text-muted-foreground">Provider</span>
              <Badge variant="outline">{user.provider}</Badge>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-muted-foreground">Allowed</span>
              {user.allowed ? (
                <div className="flex items-center gap-1 text-green-500">
                  <CheckCircle className="h-4 w-4" /> Yes
                </div>
              ) : (
                <div className="flex items-center gap-1 text-red-500">
                  <XCircle className="h-4 w-4" /> No
                </div>
              )}
            </div>
            <div className="flex justify-between">
              <span className="text-muted-foreground">Sessions</span>
              <span>{user.sessions_count}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-muted-foreground">Created</span>
              <span>{new Date(user.created_at).toLocaleString()}</span>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>API Token</CardTitle>
          </CardHeader>
          <CardContent>
            {user.api_token ? (
              <code className="block bg-muted rounded p-3 text-xs break-all">
                {user.api_token}
              </code>
            ) : (
              <p className="text-muted-foreground text-sm">No API token generated.</p>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
