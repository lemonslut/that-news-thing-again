export interface User {
  id: number
  email_address: string
  github_username?: string
  avatar_url?: string
  api_token?: string
  allowed: boolean
  created_at: string
}

export interface Article {
  id: number
  title: string
  source_name: string
  source_id?: string
  author?: string
  url: string
  image_url?: string
  published_at: string
  description?: string
  content?: string
  factual_summary?: string
  sentiment?: number
  language?: string
  is_duplicate: boolean
  story?: Pick<Story, 'id' | 'title'>
  categories: Pick<Category, 'id' | 'label'>[]
  concepts: Concept[]
  created_at: string
}

export interface Story {
  id: number
  title: string
  first_published_at?: string
  last_published_at?: string
  articles_count: number
  created_at: string
}

export interface Concept {
  id: number
  uri: string
  concept_type: 'person' | 'org' | 'loc' | 'wiki' | 'event' | 'work'
  label: string
}

export interface Category {
  id: number
  uri: string
  label: string
}

export interface Prompt {
  id: number
  name: string
  body: string
  version: number
  active: boolean
  created_at: string
}

export interface ArticleAnalysis {
  id: number
  article_id: number
  analysis_type: string
  model_used: string
  result: Record<string, unknown>
  raw_response?: Record<string, unknown>
  created_at: string
}

export interface TrendSnapshot {
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

export interface Session {
  id: number
  user_id: number
  ip_address?: string
  user_agent?: string
  created_at: string
}

export interface ArticleConcept {
  id: number
  article_id: number
  concept_id: number
  score?: number
  article?: Pick<Article, 'id' | 'title'>
  concept?: Concept
}

export interface ArticleSubject {
  id: number
  article_id: number
  concept_id: number
  article?: Pick<Article, 'id' | 'title'>
  concept?: Concept
}

export interface ArticleCategory {
  id: number
  article_id: number
  category_id: number
  weight?: number
  article?: Pick<Article, 'id' | 'title'>
  category?: Category
}

export interface Pagination {
  current_page: number
  per_page: number
  total_count: number
  total_pages: number
}

export interface PageProps {
  auth: {
    user: User | null
    authenticated: boolean
  }
  flash: {
    notice?: string
    alert?: string
  }
}
