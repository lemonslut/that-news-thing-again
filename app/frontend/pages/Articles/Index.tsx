import { Link } from '@inertiajs/react'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Pagination } from '@/components/admin/Pagination'
import { SearchInput } from '@/components/admin/SearchInput'
import { Pagination as PaginationType } from '@/types/models'
import { Eye, CheckCircle, XCircle } from 'lucide-react'

interface Article {
  id: number
  title: string
  source_name: string
  published_at: string
  story?: { id: number; title: string }
  categories: { id: number; label: string }[]
  has_summary: boolean
}

interface ArticlesIndexProps {
  records: Article[]
  pagination: PaginationType
  filters: {
    sources: string[]
  }
}

export default function ArticlesIndex({ records, pagination, filters }: ArticlesIndexProps) {
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Articles</h1>
          <p className="text-muted-foreground">Manage news articles in the system.</p>
        </div>
      </div>

      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>All Articles</CardTitle>
            <div className="w-64">
              <SearchInput baseUrl="/admin/articles" placeholder="Search articles..." />
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Title</TableHead>
                <TableHead>Source</TableHead>
                <TableHead>Published</TableHead>
                <TableHead>Story</TableHead>
                <TableHead>Summary</TableHead>
                <TableHead className="w-[80px]">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {records.map((article) => (
                <TableRow key={article.id}>
                  <TableCell className="max-w-md">
                    <Link href={`/admin/articles/${article.id}`} className="font-medium hover:underline line-clamp-2">
                      {article.title}
                    </Link>
                    <div className="flex gap-1 mt-1">
                      {article.categories.slice(0, 2).map((cat) => (
                        <Badge key={cat.id} variant="secondary" className="text-xs">
                          {cat.label}
                        </Badge>
                      ))}
                    </div>
                  </TableCell>
                  <TableCell className="text-muted-foreground">{article.source_name}</TableCell>
                  <TableCell className="text-muted-foreground">
                    {article.published_at ? new Date(article.published_at).toLocaleDateString() : '-'}
                  </TableCell>
                  <TableCell>
                    {article.story ? (
                      <Link href={`/admin/stories/${article.story.id}`} className="text-sm hover:underline">
                        {article.story.title.slice(0, 30)}...
                      </Link>
                    ) : (
                      <span className="text-muted-foreground">-</span>
                    )}
                  </TableCell>
                  <TableCell>
                    {article.has_summary ? (
                      <CheckCircle className="h-4 w-4 text-green-500" />
                    ) : (
                      <XCircle className="h-4 w-4 text-muted-foreground" />
                    )}
                  </TableCell>
                  <TableCell>
                    <Button variant="ghost" size="icon" asChild>
                      <Link href={`/admin/articles/${article.id}`}>
                        <Eye className="h-4 w-4" />
                      </Link>
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
          <Pagination pagination={pagination} baseUrl="/admin/articles" />
        </CardContent>
      </Card>
    </div>
  )
}
