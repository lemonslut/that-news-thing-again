import { useForm, Link } from '@inertiajs/react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { ArrowLeft } from 'lucide-react'

interface PromptFormProps {
  prompt: {
    id: number
    name: string
    version: number
    body: string
    active: boolean
  } | null
}

export default function PromptForm({ prompt }: PromptFormProps) {
  const isNew = !prompt
  const { data, setData, post, put, processing, errors } = useForm({
    name: prompt?.name || '',
    version: prompt?.version || 1,
    body: prompt?.body || '',
    active: prompt?.active || false
  })

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (isNew) {
      post('/admin/prompts')
    } else {
      put(`/admin/prompts/${prompt.id}`)
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="icon" asChild>
          <Link href={isNew ? '/admin/prompts' : `/admin/prompts/${prompt?.id}`}>
            <ArrowLeft className="h-4 w-4" />
          </Link>
        </Button>
        <div>
          <h1 className="text-2xl font-bold tracking-tight">
            {isNew ? 'New Prompt' : 'Edit Prompt'}
          </h1>
        </div>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Prompt Details</CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="grid gap-4 md:grid-cols-2">
              <div className="space-y-2">
                <Label htmlFor="name">Name</Label>
                <Input
                  id="name"
                  value={data.name}
                  onChange={(e) => setData('name', e.target.value)}
                  placeholder="e.g., factual_summary"
                />
                {errors.name && <p className="text-sm text-destructive">{errors.name}</p>}
              </div>

              <div className="space-y-2">
                <Label htmlFor="version">Version</Label>
                <Input
                  id="version"
                  type="number"
                  value={data.version}
                  onChange={(e) => setData('version', parseInt(e.target.value))}
                />
                {errors.version && <p className="text-sm text-destructive">{errors.version}</p>}
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="body">Body</Label>
              <Textarea
                id="body"
                value={data.body}
                onChange={(e) => setData('body', e.target.value)}
                rows={15}
                className="font-mono text-sm"
                placeholder="Enter prompt template..."
              />
              {errors.body && <p className="text-sm text-destructive">{errors.body}</p>}
            </div>

            <div className="flex gap-2">
              <Button type="submit" disabled={processing}>
                {processing ? 'Saving...' : isNew ? 'Create Prompt' : 'Save Changes'}
              </Button>
              <Button variant="outline" asChild>
                <Link href={isNew ? '/admin/prompts' : `/admin/prompts/${prompt?.id}`}>Cancel</Link>
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  )
}
