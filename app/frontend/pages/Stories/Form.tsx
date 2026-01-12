import { useForm, Link } from '@inertiajs/react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { ArrowLeft } from 'lucide-react'

interface StoryFormProps {
  story: {
    id: number
    title: string
  }
}

export default function StoryForm({ story }: StoryFormProps) {
  const { data, setData, put, processing, errors } = useForm({
    title: story.title
  })

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    put(`/admin/stories/${story.id}`)
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="icon" asChild>
          <Link href={`/admin/stories/${story.id}`}>
            <ArrowLeft className="h-4 w-4" />
          </Link>
        </Button>
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Edit Story</h1>
        </div>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Story Details</CardTitle>
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

            <div className="flex gap-2">
              <Button type="submit" disabled={processing}>
                {processing ? 'Saving...' : 'Save Changes'}
              </Button>
              <Button variant="outline" asChild>
                <Link href={`/admin/stories/${story.id}`}>Cancel</Link>
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  )
}
