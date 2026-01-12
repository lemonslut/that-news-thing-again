import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Newspaper, BookOpen, Tags, FolderTree, TrendingUp } from 'lucide-react'

interface DashboardProps {
  stats: {
    articles_count: number
    stories_count: number
    concepts_count: number
    categories_count: number
    articles_today: number
    trending_stories: number
  }
  recent_articles: {
    id: number
    title: string
    source_name: string
    published_at: string
  }[]
}

export default function Dashboard({ stats, recent_articles }: DashboardProps) {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Dashboard</h1>
        <p className="text-muted-foreground">Overview of your news aggregation system.</p>
      </div>

      {/* Stats Grid */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Articles</CardTitle>
            <Newspaper className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.articles_count.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">
              +{stats.articles_today} today
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Stories</CardTitle>
            <BookOpen className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.stories_count.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">
              {stats.trending_stories} trending
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Concepts</CardTitle>
            <Tags className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.concepts_count.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">
              People, orgs, locations
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Categories</CardTitle>
            <FolderTree className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.categories_count.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">
              Content categories
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Recent Articles */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <TrendingUp className="h-5 w-5" />
            Recent Articles
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {recent_articles.map((article) => (
              <div key={article.id} className="flex items-start justify-between gap-4">
                <div className="min-w-0 flex-1">
                  <p className="text-sm font-medium leading-tight truncate">{article.title}</p>
                  <p className="text-xs text-muted-foreground mt-1">
                    {article.source_name} &middot; {new Date(article.published_at).toLocaleDateString()}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
