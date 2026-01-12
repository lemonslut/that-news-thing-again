import { Link, router } from '@inertiajs/react'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Pagination } from '@/components/admin/Pagination'
import { Pagination as PaginationType } from '@/types/models'
import { Trash } from 'lucide-react'

interface Session {
  id: number
  user: { id: number; email_address: string; github_username?: string }
  ip_address?: string
  user_agent?: string
  created_at: string
}

interface SessionsIndexProps {
  records: Session[]
  pagination: PaginationType
}

export default function SessionsIndex({ records, pagination }: SessionsIndexProps) {
  const handleDelete = (id: number) => {
    if (confirm('Terminate this session?')) {
      router.delete(`/admin/sessions/${id}`)
    }
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Sessions</h1>
        <p className="text-muted-foreground">Active user sessions.</p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>All Sessions</CardTitle>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>User</TableHead>
                <TableHead>IP Address</TableHead>
                <TableHead>User Agent</TableHead>
                <TableHead>Created</TableHead>
                <TableHead className="w-[80px]">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {records.map((session) => (
                <TableRow key={session.id}>
                  <TableCell>
                    <Link href={`/admin/users/${session.user.id}`} className="font-medium hover:underline">
                      {session.user.github_username || session.user.email_address}
                    </Link>
                  </TableCell>
                  <TableCell className="text-muted-foreground font-mono text-sm">
                    {session.ip_address || '-'}
                  </TableCell>
                  <TableCell className="text-muted-foreground text-xs max-w-xs truncate">
                    {session.user_agent || '-'}
                  </TableCell>
                  <TableCell className="text-muted-foreground">
                    {new Date(session.created_at).toLocaleString()}
                  </TableCell>
                  <TableCell>
                    <Button variant="ghost" size="icon" onClick={() => handleDelete(session.id)}>
                      <Trash className="h-4 w-4" />
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
          <Pagination pagination={pagination} baseUrl="/admin/sessions" />
        </CardContent>
      </Card>
    </div>
  )
}
