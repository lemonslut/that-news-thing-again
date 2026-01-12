import { useState, useCallback } from 'react'
import { router } from '@inertiajs/react'
import { Input } from '@/components/ui/input'
import { Search, X } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { useDebouncedCallback } from '@/lib/hooks'

interface SearchInputProps {
  baseUrl: string
  placeholder?: string
  defaultValue?: string
}

export function SearchInput({ baseUrl, placeholder = 'Search...', defaultValue = '' }: SearchInputProps) {
  const [value, setValue] = useState(defaultValue)

  const debouncedSearch = useDebouncedCallback((query: string) => {
    router.get(baseUrl, query ? { q: query } : {}, { preserveState: true, preserveScroll: true })
  }, 300)

  const handleChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    const newValue = e.target.value
    setValue(newValue)
    debouncedSearch(newValue)
  }, [debouncedSearch])

  const handleClear = useCallback(() => {
    setValue('')
    router.get(baseUrl, {}, { preserveState: true, preserveScroll: true })
  }, [baseUrl])

  return (
    <div className="relative">
      <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
      <Input
        type="text"
        placeholder={placeholder}
        value={value}
        onChange={handleChange}
        className="pl-10 pr-10"
      />
      {value && (
        <Button
          variant="ghost"
          size="icon"
          className="absolute right-1 top-1/2 h-7 w-7 -translate-y-1/2"
          onClick={handleClear}
        >
          <X className="h-4 w-4" />
        </Button>
      )}
    </div>
  )
}
