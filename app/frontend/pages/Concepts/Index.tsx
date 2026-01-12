import { Link } from '@inertiajs/react'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Pagination } from '@/components/admin/Pagination'
import { SearchInput } from '@/components/admin/SearchInput'
import { Pagination as PaginationType } from '@/types/models'
import { Eye } from 'lucide-react'

interface Concept {
  id: number
  label: string
  concept_type: string
  uri: string
}

interface ConceptsIndexProps {
  records: Concept[]
  pagination: PaginationType
  types: string[]
}

const typeColors: Record<string, string> = {
  person: 'bg-blue-500/20 text-blue-400',
  org: 'bg-purple-500/20 text-purple-400',
  loc: 'bg-green-500/20 text-green-400',
  wiki: 'bg-yellow-500/20 text-yellow-400',
  event: 'bg-red-500/20 text-red-400',
  work: 'bg-orange-500/20 text-orange-400'
}

export default function ConceptsIndex({ records, pagination, types }: ConceptsIndexProps) {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Concepts</h1>
        <p className="text-muted-foreground">Named entities: people, organizations, locations, topics.</p>
      </div>

      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>All Concepts</CardTitle>
            <div className="w-64">
              <SearchInput baseUrl="/admin/concepts" placeholder="Search concepts..." />
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Label</TableHead>
                <TableHead>Type</TableHead>
                <TableHead>URI</TableHead>
                <TableHead className="w-[80px]">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {records.map((concept) => (
                <TableRow key={concept.id}>
                  <TableCell>
                    <Link href={`/admin/concepts/${concept.id}`} className="font-medium hover:underline">
                      {concept.label}
                    </Link>
                  </TableCell>
                  <TableCell>
                    <Badge className={typeColors[concept.concept_type] || ''} variant="outline">
                      {concept.concept_type}
                    </Badge>
                  </TableCell>
                  <TableCell className="text-muted-foreground text-xs font-mono truncate max-w-xs">
                    {concept.uri}
                  </TableCell>
                  <TableCell>
                    <Button variant="ghost" size="icon" asChild>
                      <Link href={`/admin/concepts/${concept.id}`}>
                        <Eye className="h-4 w-4" />
                      </Link>
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
          <Pagination pagination={pagination} baseUrl="/admin/concepts" />
        </CardContent>
      </Card>
    </div>
  )
}
