import { Link, router } from '@inertiajs/react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { ArrowLeft, Pencil, Trash, Zap } from 'lucide-react'
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

interface PromptShowProps {
  prompt: {
    id: number
    name: string
    version: number
    active: boolean
    body: string
    created_at: string
  }
}

export default function PromptShow({ prompt }: PromptShowProps) {
  const handleDelete = () => {
    router.delete(`/admin/prompts/${prompt.id}`)
  }

  const handleActivate = () => {
    router.post(`/admin/prompts/${prompt.id}/activate`)
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Button variant="ghost" size="icon" asChild>
            <Link href="/admin/prompts">
              <ArrowLeft className="h-4 w-4" />
            </Link>
          </Button>
          <div>
            <div className="flex items-center gap-2">
              <h1 className="text-2xl font-bold tracking-tight">{prompt.name}</h1>
              <Badge variant="outline">v{prompt.version}</Badge>
              {prompt.active && <Badge className="bg-green-500/20 text-green-400">Active</Badge>}
            </div>
            <p className="text-muted-foreground text-sm">
              Created {new Date(prompt.created_at).toLocaleString()}
            </p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          {!prompt.active && (
            <Button variant="outline" size="sm" onClick={handleActivate}>
              <Zap className="h-4 w-4 mr-2" />
              Activate
            </Button>
          )}
          <Button variant="outline" size="sm" asChild>
            <Link href={`/admin/prompts/${prompt.id}/edit`}>
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
                <AlertDialogTitle>Delete Prompt</AlertDialogTitle>
                <AlertDialogDescription>
                  Are you sure? This cannot be undone.
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

      <Card>
        <CardHeader>
          <CardTitle>Prompt Body</CardTitle>
        </CardHeader>
        <CardContent>
          <pre className="bg-muted rounded-lg p-4 text-sm whitespace-pre-wrap overflow-x-auto">
            {prompt.body}
          </pre>
        </CardContent>
      </Card>
    </div>
  )
}
