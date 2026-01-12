import { Link } from '@inertiajs/react'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Pagination } from '@/components/admin/Pagination'
import { SearchInput } from '@/components/admin/SearchInput'
import { Pagination as PaginationType } from '@/types/models'
import { Eye, CheckCircle, XCircle } from 'lucide-react'

interface User {
  id: number
  email_address: string
  github_username?: string
  avatar_url?: string
  provider: string
  allowed: boolean
  created_at: string
}

interface UsersIndexProps {
  records: User[]
  pagination: PaginationType
}

export default function UsersIndex({ records, pagination }: UsersIndexProps) {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Users</h1>
        <p className="text-muted-foreground">Manage admin users and access.</p>
      </div>

      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>All Users</CardTitle>
            <div className="w-64">
              <SearchInput baseUrl="/admin/users" placeholder="Search users..." />
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>User</TableHead>
                <TableHead>Provider</TableHead>
                <TableHead>Allowed</TableHead>
                <TableHead>Created</TableHead>
                <TableHead className="w-[80px]">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {records.map((user) => (
                <TableRow key={user.id}>
                  <TableCell>
                    <div className="flex items-center gap-3">
                      {user.avatar_url && (
                        <img src={user.avatar_url} alt="" className="h-8 w-8 rounded-full" />
                      )}
                      <div>
                        <Link href={`/admin/users/${user.id}`} className="font-medium hover:underline">
                          {user.github_username || user.email_address}
                        </Link>
                        {user.github_username && (
                          <p className="text-xs text-muted-foreground">{user.email_address}</p>
                        )}
                      </div>
                    </div>
                  </TableCell>
                  <TableCell>
                    <Badge variant="outline">{user.provider}</Badge>
                  </TableCell>
                  <TableCell>
                    {user.allowed ? (
                      <CheckCircle className="h-4 w-4 text-green-500" />
                    ) : (
                      <XCircle className="h-4 w-4 text-red-500" />
                    )}
                  </TableCell>
                  <TableCell className="text-muted-foreground">
                    {new Date(user.created_at).toLocaleDateString()}
                  </TableCell>
                  <TableCell>
                    <Button variant="ghost" size="icon" asChild>
                      <Link href={`/admin/users/${user.id}`}>
                        <Eye className="h-4 w-4" />
                      </Link>
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
          <Pagination pagination={pagination} baseUrl="/admin/users" />
        </CardContent>
      </Card>
    </div>
  )
}
