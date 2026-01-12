import { Link } from '@inertiajs/react'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Pagination } from '@/components/admin/Pagination'
import { SearchInput } from '@/components/admin/SearchInput'
import { Pagination as PaginationType } from '@/types/models'
import { Eye } from 'lucide-react'

interface Category {
  id: number
  label: string
  uri: string
}

interface CategoriesIndexProps {
  records: Category[]
  pagination: PaginationType
}

export default function CategoriesIndex({ records, pagination }: CategoriesIndexProps) {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Categories</h1>
        <p className="text-muted-foreground">Content categories from NewsAPI.ai.</p>
      </div>

      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>All Categories</CardTitle>
            <div className="w-64">
              <SearchInput baseUrl="/admin/categories" placeholder="Search categories..." />
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Label</TableHead>
                <TableHead>URI</TableHead>
                <TableHead className="w-[80px]">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {records.map((category) => (
                <TableRow key={category.id}>
                  <TableCell>
                    <Link href={`/admin/categories/${category.id}`} className="font-medium hover:underline">
                      {category.label}
                    </Link>
                  </TableCell>
                  <TableCell className="text-muted-foreground text-xs font-mono truncate max-w-md">
                    {category.uri}
                  </TableCell>
                  <TableCell>
                    <Button variant="ghost" size="icon" asChild>
                      <Link href={`/admin/categories/${category.id}`}>
                        <Eye className="h-4 w-4" />
                      </Link>
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
          <Pagination pagination={pagination} baseUrl="/admin/categories" />
        </CardContent>
      </Card>
    </div>
  )
}
