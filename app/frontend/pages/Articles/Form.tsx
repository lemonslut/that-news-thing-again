import { useForm, Link } from '@inertiajs/react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { ArrowLeft } from 'lucide-react'

interface ArticleFormProps {
  article: {
    id: number
    title: string
    description?: string
    content?: string
    factual_summary?: string
    story?: { id: number; title: string }
  }
  stories: { label: string; value: number }[]
}

export default function ArticleForm({ article, stories }: ArticleFormProps) {
  const { data, setData, put, processing, errors } = useForm({
    title: article.title,
    description: article.description || '',
    factual_summary: article.factual_summary || '',
    story_id: article.story?.id || ''
  })

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    put(`/admin/articles/${article.id}`)
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="icon" asChild>
          <Link href={`/admin/articles/${article.id}`}>
            <ArrowLeft className="h-4 w-4" />
          </Link>
        </Button>
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Edit Article</h1>
          <p className="text-muted-foreground">Update article details</p>
        </div>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Article Details</CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="title">Title</Label>
              <Input
                id="title"
                value={data.title}
                onChange={(e) => setData('title', e.target.value)}
              />
              {errors.title && <p className="text-sm text-destructive">{errors.title}</p>}
            </div>

            <div className="space-y-2">
              <Label htmlFor="description">Description</Label>
              <Textarea
                id="description"
                value={data.description}
                onChange={(e) => setData('description', e.target.value)}
                rows={3}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="factual_summary">Factual Summary</Label>
              <Textarea
                id="factual_summary"
                value={data.factual_summary}
                onChange={(e) => setData('factual_summary', e.target.value)}
                rows={5}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="story_id">Story</Label>
              <select
                id="story_id"
                value={data.story_id}
                onChange={(e) => setData('story_id', e.target.value)}
                className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
              >
                <option value="">No story</option>
                {stories.map((story) => (
                  <option key={story.value} value={story.value}>
                    {story.label}
                  </option>
                ))}
              </select>
            </div>

            <div className="flex gap-2">
              <Button type="submit" disabled={processing}>
                {processing ? 'Saving...' : 'Save Changes'}
              </Button>
              <Button variant="outline" asChild>
                <Link href={`/admin/articles/${article.id}`}>Cancel</Link>
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  )
}
