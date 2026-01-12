import { Link } from '@inertiajs/react'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Pagination } from '@/components/admin/Pagination'
import { SearchInput } from '@/components/admin/SearchInput'
import { Pagination as PaginationType } from '@/types/models'
import { Eye, Plus } from 'lucide-react'

interface Prompt {
  id: number
  name: string
  version: number
  active: boolean
  created_at: string
}

interface PromptsIndexProps {
  records: Prompt[]
  pagination: PaginationType
}

export default function PromptsIndex({ records, pagination }: PromptsIndexProps) {
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Prompts</h1>
          <p className="text-muted-foreground">LLM prompts with version control.</p>
        </div>
        <Button asChild>
          <Link href="/admin/prompts/new">
            <Plus className="h-4 w-4 mr-2" />
            New Prompt
          </Link>
        </Button>
      </div>

      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>All Prompts</CardTitle>
            <div className="w-64">
              <SearchInput baseUrl="/admin/prompts" placeholder="Search prompts..." />
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Name</TableHead>
                <TableHead>Version</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Created</TableHead>
                <TableHead className="w-[80px]">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {records.map((prompt) => (
                <TableRow key={prompt.id}>
                  <TableCell>
                    <Link href={`/admin/prompts/${prompt.id}`} className="font-medium hover:underline">
                      {prompt.name}
                    </Link>
                  </TableCell>
                  <TableCell>v{prompt.version}</TableCell>
                  <TableCell>
                    {prompt.active ? (
                      <Badge className="bg-green-500/20 text-green-400">Active</Badge>
                    ) : (
                      <Badge variant="secondary">Inactive</Badge>
                    )}
                  </TableCell>
                  <TableCell className="text-muted-foreground">
                    {new Date(prompt.created_at).toLocaleDateString()}
                  </TableCell>
                  <TableCell>
                    <Button variant="ghost" size="icon" asChild>
                      <Link href={`/admin/prompts/${prompt.id}`}>
                        <Eye className="h-4 w-4" />
                      </Link>
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
          <Pagination pagination={pagination} baseUrl="/admin/prompts" />
        </CardContent>
      </Card>
    </div>
  )
}
