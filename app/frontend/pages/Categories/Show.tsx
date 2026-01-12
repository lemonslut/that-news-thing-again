import { Link, router } from '@inertiajs/react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
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

interface CategoryShowProps {
  category: {
    id: number
    label: string
    uri: string
    articles_count: number
    recent_articles: { id: number; title: string; published_at?: string }[]
  }
}

export default function CategoryShow({ category }: CategoryShowProps) {
  const handleDelete = () => {
    router.delete(`/admin/categories/${category.id}`)
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Button variant="ghost" size="icon" asChild>
            <Link href="/admin/categories">
              <ArrowLeft className="h-4 w-4" />
            </Link>
          </Button>
          <div>
            <h1 className="text-2xl font-bold tracking-tight">{category.label}</h1>
            <p className="text-muted-foreground text-sm font-mono">{category.uri}</p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline" size="sm" asChild>
            <Link href={`/admin/categories/${category.id}/edit`}>
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
                <AlertDialogTitle>Delete Category</AlertDialogTitle>
                <AlertDialogDescription>
                  This will remove all article associations.
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

      <div className="grid gap-6 md:grid-cols-3">
        <div className="md:col-span-2">
          <Card>
            <CardHeader>
              <CardTitle>Recent Articles ({category.articles_count} total)</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                {category.recent_articles.map((article) => (
                  <div key={article.id} className="flex items-start justify-between">
                    <Link href={`/admin/articles/${article.id}`} className="hover:underline text-sm">
                      {article.title}
                    </Link>
                    <span className="text-xs text-muted-foreground">
                      {article.published_at ? new Date(article.published_at).toLocaleDateString() : '-'}
                    </span>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </div>

        <Card>
          <CardHeader>
            <CardTitle>Details</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3 text-sm">
            <div className="flex justify-between">
              <span className="text-muted-foreground">Articles</span>
              <span>{category.articles_count}</span>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
