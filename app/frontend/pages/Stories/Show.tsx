import { Link, router } from '@inertiajs/react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { ArrowLeft, Pencil, Trash } from 'lucide-react'
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

interface StoryShowProps {
  story: {
    id: number
    title: string
    articles_count: number
    first_published_at?: string
    last_published_at?: string
    articles: { id: number; title: string; source_name: string; published_at?: string }[]
  }
}

export default function StoryShow({ story }: StoryShowProps) {
  const handleDelete = () => {
    router.delete(`/admin/stories/${story.id}`)
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Button variant="ghost" size="icon" asChild>
            <Link href="/admin/stories">
              <ArrowLeft className="h-4 w-4" />
            </Link>
          </Button>
          <div>
            <h1 className="text-2xl font-bold tracking-tight">{story.title}</h1>
            <p className="text-muted-foreground">{story.articles_count} articles</p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline" size="sm" asChild>
            <Link href={`/admin/stories/${story.id}/edit`}>
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
                <AlertDialogTitle>Delete Story</AlertDialogTitle>
                <AlertDialogDescription>
                  Are you sure? Articles will be unlinked but not deleted.
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
          <CardTitle>Articles in this Story</CardTitle>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Title</TableHead>
                <TableHead>Source</TableHead>
                <TableHead>Published</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {story.articles.map((article) => (
                <TableRow key={article.id}>
                  <TableCell>
                    <Link href={`/admin/articles/${article.id}`} className="hover:underline">
                      {article.title}
                    </Link>
                  </TableCell>
                  <TableCell className="text-muted-foreground">{article.source_name}</TableCell>
                  <TableCell className="text-muted-foreground">
                    {article.published_at ? new Date(article.published_at).toLocaleDateString() : '-'}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  )
}
