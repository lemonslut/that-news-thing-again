import { Link } from '@inertiajs/react'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Pagination } from '@/components/admin/Pagination'
import { SearchInput } from '@/components/admin/SearchInput'
import { Pagination as PaginationType } from '@/types/models'
import { Eye } from 'lucide-react'

interface Story {
  id: number
  title: string
  articles_count: number
  first_published_at?: string
  last_published_at?: string
}

interface StoriesIndexProps {
  records: Story[]
  pagination: PaginationType
}

export default function StoriesIndex({ records, pagination }: StoriesIndexProps) {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Stories</h1>
        <p className="text-muted-foreground">Groups of related articles across sources.</p>
      </div>

      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>All Stories</CardTitle>
            <div className="w-64">
              <SearchInput baseUrl="/admin/stories" placeholder="Search stories..." />
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Title</TableHead>
                <TableHead>Articles</TableHead>
                <TableHead>First Published</TableHead>
                <TableHead>Last Published</TableHead>
                <TableHead className="w-[80px]">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {records.map((story) => (
                <TableRow key={story.id}>
                  <TableCell>
                    <Link href={`/admin/stories/${story.id}`} className="font-medium hover:underline">
                      {story.title}
                    </Link>
                  </TableCell>
                  <TableCell>{story.articles_count}</TableCell>
                  <TableCell className="text-muted-foreground">
                    {story.first_published_at ? new Date(story.first_published_at).toLocaleDateString() : '-'}
                  </TableCell>
                  <TableCell className="text-muted-foreground">
                    {story.last_published_at ? new Date(story.last_published_at).toLocaleDateString() : '-'}
                  </TableCell>
                  <TableCell>
                    <Button variant="ghost" size="icon" asChild>
                      <Link href={`/admin/stories/${story.id}`}>
                        <Eye className="h-4 w-4" />
                      </Link>
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
          <Pagination pagination={pagination} baseUrl="/admin/stories" />
        </CardContent>
      </Card>
    </div>
  )
}
