import { Link, router } from '@inertiajs/react'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Pagination } from '@/components/admin/Pagination'
import { Pagination as PaginationType } from '@/types/models'
import { Eye, Trash } from 'lucide-react'

interface Analysis {
  id: number
  analysis_type: string
  model_used: string
  article: { id: number; title: string }
  created_at: string
}

interface AnalysesIndexProps {
  records: Analysis[]
  pagination: PaginationType
  types: string[]
}

export default function ArticleAnalysesIndex({ records, pagination }: AnalysesIndexProps) {
  const handleDelete = (id: number) => {
    if (confirm('Delete this analysis?')) {
      router.delete(`/admin/article_analyses/${id}`)
    }
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Article Analyses</h1>
        <p className="text-muted-foreground">LLM analysis results for articles.</p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>All Analyses</CardTitle>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Article</TableHead>
                <TableHead>Type</TableHead>
                <TableHead>Model</TableHead>
                <TableHead>Created</TableHead>
                <TableHead className="w-[100px]">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {records.map((analysis) => (
                <TableRow key={analysis.id}>
                  <TableCell>
                    <Link href={`/admin/articles/${analysis.article.id}`} className="hover:underline text-sm">
                      {analysis.article.title.slice(0, 50)}...
                    </Link>
                  </TableCell>
                  <TableCell>
                    <Badge variant="outline">{analysis.analysis_type}</Badge>
                  </TableCell>
                  <TableCell className="text-muted-foreground text-sm">{analysis.model_used}</TableCell>
                  <TableCell className="text-muted-foreground">
                    {new Date(analysis.created_at).toLocaleString()}
                  </TableCell>
                  <TableCell>
                    <div className="flex gap-1">
                      <Button variant="ghost" size="icon" asChild>
                        <Link href={`/admin/article_analyses/${analysis.id}`}>
                          <Eye className="h-4 w-4" />
                        </Link>
                      </Button>
                      <Button variant="ghost" size="icon" onClick={() => handleDelete(analysis.id)}>
                        <Trash className="h-4 w-4" />
                      </Button>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
          <Pagination pagination={pagination} baseUrl="/admin/article_analyses" />
        </CardContent>
      </Card>
    </div>
  )
}
