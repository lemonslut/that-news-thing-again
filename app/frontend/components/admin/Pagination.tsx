import { router } from '@inertiajs/react'
import { Button } from '@/components/ui/button'
import { ChevronLeft, ChevronRight, ChevronsLeft, ChevronsRight } from 'lucide-react'
import { Pagination as PaginationType } from '@/types/models'

interface PaginationProps {
  pagination: PaginationType
  baseUrl: string
  preserveState?: boolean
}

export function Pagination({ pagination, baseUrl, preserveState = true }: PaginationProps) {
  const { current_page, total_pages, total_count, per_page } = pagination

  if (total_pages <= 1) return null

  const goToPage = (page: number) => {
    router.get(baseUrl, { page }, { preserveState, preserveScroll: true })
  }

  const startItem = (current_page - 1) * per_page + 1
  const endItem = Math.min(current_page * per_page, total_count)

  return (
    <div className="flex items-center justify-between px-2 py-4">
      <div className="text-sm text-muted-foreground">
        Showing {startItem}-{endItem} of {total_count.toLocaleString()}
      </div>
      <div className="flex items-center gap-1">
        <Button
          variant="outline"
          size="icon"
          onClick={() => goToPage(1)}
          disabled={current_page === 1}
        >
          <ChevronsLeft className="h-4 w-4" />
        </Button>
        <Button
          variant="outline"
          size="icon"
          onClick={() => goToPage(current_page - 1)}
          disabled={current_page === 1}
        >
          <ChevronLeft className="h-4 w-4" />
        </Button>
        <span className="px-4 text-sm">
          Page {current_page} of {total_pages}
        </span>
        <Button
          variant="outline"
          size="icon"
          onClick={() => goToPage(current_page + 1)}
          disabled={current_page === total_pages}
        >
          <ChevronRight className="h-4 w-4" />
        </Button>
        <Button
          variant="outline"
          size="icon"
          onClick={() => goToPage(total_pages)}
          disabled={current_page === total_pages}
        >
          <ChevronsRight className="h-4 w-4" />
        </Button>
      </div>
    </div>
  )
}
