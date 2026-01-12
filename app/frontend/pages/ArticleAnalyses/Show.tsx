import { Link } from '@inertiajs/react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { ArrowLeft } from 'lucide-react'

interface AnalysisShowProps {
  analysis: {
    id: number
    analysis_type: string
    model_used: string
    article: { id: number; title: string }
    result: Record<string, unknown>
    raw_response?: Record<string, unknown>
    created_at: string
  }
}

export default function ArticleAnalysisShow({ analysis }: AnalysisShowProps) {
  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="icon" asChild>
          <Link href="/admin/article_analyses">
            <ArrowLeft className="h-4 w-4" />
          </Link>
        </Button>
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-2xl font-bold tracking-tight">Analysis #{analysis.id}</h1>
            <Badge variant="outline">{analysis.analysis_type}</Badge>
          </div>
          <Link href={`/admin/articles/${analysis.article.id}`} className="text-muted-foreground hover:underline">
            {analysis.article.title}
          </Link>
        </div>
      </div>

      <div className="grid gap-6">
        <Card>
          <CardHeader>
            <CardTitle>Result</CardTitle>
          </CardHeader>
          <CardContent>
            <pre className="bg-muted rounded-lg p-4 text-sm overflow-x-auto max-h-96">
              {JSON.stringify(analysis.result, null, 2)}
            </pre>
          </CardContent>
        </Card>

        {analysis.raw_response && (
          <Card>
            <CardHeader>
              <CardTitle>Raw Response</CardTitle>
            </CardHeader>
            <CardContent>
              <pre className="bg-muted rounded-lg p-4 text-sm overflow-x-auto max-h-96">
                {JSON.stringify(analysis.raw_response, null, 2)}
              </pre>
            </CardContent>
          </Card>
        )}
      </div>
    </div>
  )
}
