import { useForm, Link } from '@inertiajs/react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { ArrowLeft } from 'lucide-react'

interface CategoryFormProps {
  category: {
    id: number
    label: string
    uri: string
  }
}

export default function CategoryForm({ category }: CategoryFormProps) {
  const { data, setData, put, processing, errors } = useForm({
    label: category.label,
    uri: category.uri
  })

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    put(`/admin/categories/${category.id}`)
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="icon" asChild>
          <Link href={`/admin/categories/${category.id}`}>
            <ArrowLeft className="h-4 w-4" />
          </Link>
        </Button>
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Edit Category</h1>
        </div>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Category Details</CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="label">Label</Label>
              <Input
                id="label"
                value={data.label}
                onChange={(e) => setData('label', e.target.value)}
              />
              {errors.label && <p className="text-sm text-destructive">{errors.label}</p>}
            </div>

            <div className="space-y-2">
              <Label htmlFor="uri">URI</Label>
              <Input
                id="uri"
                value={data.uri}
                onChange={(e) => setData('uri', e.target.value)}
              />
              {errors.uri && <p className="text-sm text-destructive">{errors.uri}</p>}
            </div>

            <div className="flex gap-2">
              <Button type="submit" disabled={processing}>
                {processing ? 'Saving...' : 'Save Changes'}
              </Button>
              <Button variant="outline" asChild>
                <Link href={`/admin/categories/${category.id}`}>Cancel</Link>
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  )
}
