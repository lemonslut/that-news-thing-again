import { Link, router } from '@inertiajs/react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Separator } from '@/components/ui/separator'
import { ArrowLeft, ExternalLink, Pencil, RefreshCw, Trash } from 'lucide-react'
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

interface ArticleShowProps {
  article: {
    id: number
    title: string
    source_name: string
    description?: string
    content?: string
    factual_summary?: string
    url: string
    image_url?: string
    published_at: string
    sentiment?: number
    language?: string
    is_duplicate: boolean
    story?: { id: number; title: string }
    categories: { id: number; label: string; uri: string }[]
    concepts: { id: number; label: string; concept_type: string; uri: string }[]
    analyses: { id: number; analysis_type: string; model_used: string; created_at: string }[]
  }
}

export default function ArticleShow({ article }: ArticleShowProps) {
  const handleDelete = () => {
    router.delete(`/admin/articles/${article.id}`)
  }

  const handleReanalyze = () => {
    router.post(`/admin/articles/${article.id}/reanalyze`)
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Button variant="ghost" size="icon" asChild>
            <Link href="/admin/articles">
              <ArrowLeft className="h-4 w-4" />
            </Link>
          </Button>
          <div>
            <h1 className="text-2xl font-bold tracking-tight line-clamp-2">{article.title}</h1>
            <p className="text-muted-foreground">{article.source_name}</p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline" size="sm" onClick={handleReanalyze}>
            <RefreshCw className="h-4 w-4 mr-2" />
            Re-analyze
          </Button>
          <Button variant="outline" size="sm" asChild>
            <Link href={`/admin/articles/${article.id}/edit`}>
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
                <AlertDialogTitle>Delete Article</AlertDialogTitle>
                <AlertDialogDescription>
                  Are you sure you want to delete this article? This action cannot be undone.
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
        <div className="md:col-span-2 space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Details</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              {article.image_url && (
                <img src={article.image_url} alt={article.title} className="w-full rounded-lg max-h-64 object-cover" />
              )}

              <div className="flex items-center gap-2">
                <a
                  href={article.url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-sm text-primary hover:underline flex items-center gap-1"
                >
                  View original article <ExternalLink className="h-3 w-3" />
                </a>
              </div>

              <Separator />

              {article.factual_summary && (
                <div>
                  <h3 className="font-medium mb-2">Factual Summary</h3>
                  <p className="text-sm text-muted-foreground whitespace-pre-wrap">{article.factual_summary}</p>
                </div>
              )}

              {article.description && (
                <div>
                  <h3 className="font-medium mb-2">Description</h3>
                  <p className="text-sm text-muted-foreground">{article.description}</p>
                </div>
              )}

              {article.content && (
                <div>
                  <h3 className="font-medium mb-2">Content</h3>
                  <p className="text-sm text-muted-foreground whitespace-pre-wrap max-h-96 overflow-y-auto">
                    {article.content}
                  </p>
                </div>
              )}
            </CardContent>
          </Card>

          {article.analyses.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle>Analyses</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  {article.analyses.map((analysis) => (
                    <div key={analysis.id} className="flex items-center justify-between py-2 border-b last:border-0">
                      <div>
                        <span className="font-medium">{analysis.analysis_type}</span>
                        <span className="text-sm text-muted-foreground ml-2">({analysis.model_used})</span>
                      </div>
                      <span className="text-sm text-muted-foreground">
                        {new Date(analysis.created_at).toLocaleString()}
                      </span>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          )}
        </div>

        <div className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Metadata</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3 text-sm">
              <div className="flex justify-between">
                <span className="text-muted-foreground">Published</span>
                <span>{new Date(article.published_at).toLocaleString()}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Language</span>
                <span>{article.language || '-'}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Sentiment</span>
                <span>{article.sentiment?.toFixed(2) || '-'}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Duplicate</span>
                <span>{article.is_duplicate ? 'Yes' : 'No'}</span>
              </div>
              {article.story && (
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Story</span>
                  <Link href={`/admin/stories/${article.story.id}`} className="hover:underline">
                    {article.story.title.slice(0, 20)}...
                  </Link>
                </div>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Categories</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="flex flex-wrap gap-2">
                {article.categories.map((cat) => (
                  <Badge key={cat.id} variant="secondary">
                    {cat.label}
                  </Badge>
                ))}
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Concepts</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="flex flex-wrap gap-2">
                {article.concepts.map((concept) => (
                  <Badge key={concept.id} variant="outline">
                    {concept.label}
                    <span className="ml-1 text-xs text-muted-foreground">({concept.concept_type})</span>
                  </Badge>
                ))}
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  )
}
