import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Pagination } from '@/components/admin/Pagination'
import { Pagination as PaginationType } from '@/types/models'
import { TrendingUp, TrendingDown, Minus } from 'lucide-react'

interface TrendSnapshot {
  id: number
  trendable_type: string
  trendable_id: number
  trendable_label?: string
  period_start: string
  period_type: 'hour' | 'day'
  article_count: number
  rank?: number
  previous_rank?: number
  velocity: number
}

interface TrendSnapshotsIndexProps {
  records: TrendSnapshot[]
  pagination: PaginationType
  types: string[]
  periods: string[]
}

export default function TrendSnapshotsIndex({ records, pagination }: TrendSnapshotsIndexProps) {
  const getRankChange = (current?: number, previous?: number) => {
    if (!current || !previous) return null
    const change = previous - current
    if (change > 0) return { icon: TrendingUp, color: 'text-green-500', value: `+${change}` }
    if (change < 0) return { icon: TrendingDown, color: 'text-red-500', value: String(change) }
    return { icon: Minus, color: 'text-muted-foreground', value: '0' }
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Trend Snapshots</h1>
        <p className="text-muted-foreground">Trending stories, concepts, and categories.</p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Recent Trends</CardTitle>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Entity</TableHead>
                <TableHead>Type</TableHead>
                <TableHead>Period</TableHead>
                <TableHead>Articles</TableHead>
                <TableHead>Rank</TableHead>
                <TableHead>Velocity</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {records.map((snapshot) => {
                const rankChange = getRankChange(snapshot.rank, snapshot.previous_rank)
                return (
                  <TableRow key={snapshot.id}>
                    <TableCell className="font-medium">
                      {snapshot.trendable_label || `#${snapshot.trendable_id}`}
                    </TableCell>
                    <TableCell>
                      <Badge variant="outline">{snapshot.trendable_type}</Badge>
                    </TableCell>
                    <TableCell>
                      <div className="text-sm">
                        <span className="text-muted-foreground">{snapshot.period_type}</span>
                        <br />
                        <span className="text-xs">{new Date(snapshot.period_start).toLocaleString()}</span>
                      </div>
                    </TableCell>
                    <TableCell>{snapshot.article_count}</TableCell>
                    <TableCell>
                      <div className="flex items-center gap-1">
                        <span>#{snapshot.rank || '-'}</span>
                        {rankChange && (
                          <span className={`flex items-center text-xs ${rankChange.color}`}>
                            <rankChange.icon className="h-3 w-3" />
                            {rankChange.value}
                          </span>
                        )}
                      </div>
                    </TableCell>
                    <TableCell>{snapshot.velocity.toFixed(2)}</TableCell>
                  </TableRow>
                )
              })}
            </TableBody>
          </Table>
          <Pagination pagination={pagination} baseUrl="/admin/trend_snapshots" />
        </CardContent>
      </Card>
    </div>
  )
}
