# Architecture Overview

## System Diagram

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  NewsAPI    │────▶│   Rails     │────▶│ PostgreSQL  │
└─────────────┘     │   App       │     └─────────────┘
                    │             │            │
┌─────────────┐     │  ┌───────┐  │     ┌──────┴──────┐
│ OpenRouter  │◀────│  │Sidekiq│  │     │  Articles   │
│  (LLM)      │     │  └───────┘  │     │  Analyses   │
└─────────────┘     └──────┬──────┘     └─────────────┘
                           │
                    ┌──────┴──────┐
                    │    Redis    │
                    └─────────────┘
```

## Data Flow

### 1. Fetch Headlines

```
NewsAPI ─── HTTP ───▶ NewsApi::Client ───▶ FetchHeadlinesJob ───▶ Article (PostgreSQL)
```

1. `FetchHeadlinesJob` is triggered (manually or scheduled)
2. `NewsApi::Client` makes HTTP request to NewsAPI
3. Response is parsed and each article is saved via `Article.upsert_from_news_api`
4. Duplicates are detected by unique URL constraint

### 2. Analyze Articles

```
Article ───▶ AnalyzeArticleJob ───▶ Completions::Client ───▶ OpenRouter ───▶ ArticleAnalysis
```

1. `AnalyzeArticleJob` receives an article ID
2. `Completions::Client` builds a prompt with article data
3. OpenRouter routes to the selected LLM (default: Claude Haiku)
4. LLM returns structured JSON analysis
5. `ArticleAnalysis` record is created with results

### 3. Query & Display

```
ArticleAnalysis ───▶ Scopes/Queries ───▶ Application/Export
```

Articles and analyses are queried via ActiveRecord scopes for:
- Trend analysis (tag counts, category distribution)
- Timeline queries (articles over time)
- Filtering (by category, tag, political lean)

## Components

### Models

**Article** — Source of truth for news content
- Stores raw NewsAPI payload in JSONB
- Indexed by URL (unique), published_at, source_name

**ArticleAnalysis** — LLM-generated metadata
- One-to-one with Article
- Stores category, tags, entities, political lean, calm summary
- Tags indexed with GIN for fast `@>` queries

### Services

**NewsApi::Client** — Thin wrapper around NewsAPI
- Handles authentication, error mapping
- Uses Faraday for HTTP

**Completions::Client** — LLM interface via OpenRouter
- Uses ruby-openai gem pointed at OpenRouter
- Extracts JSON from potentially chatty LLM responses
- Contains the analysis prompt

### Jobs

**FetchHeadlinesJob** — Pulls from NewsAPI
- Idempotent (upserts by URL)
- Returns stats for monitoring

**AnalyzeArticleJob** — Runs LLM analysis
- Idempotent (skips if analysis exists)
- Supports model override

## Storage

### PostgreSQL

Primary data store. Chosen because:
- JSONB for flexible payload storage with query capability
- GIN indexes for efficient tag queries
- Reliable, well-understood, easy to backup

### Redis

Sidekiq job queue backend. Stores:
- Pending jobs
- Job metadata
- No persistent application data

## External Dependencies

### NewsAPI

- Rate limited (dev key: 100 requests/day)
- Returns truncated content (200 chars)
- Provides source, author, title, description, URL, image, timestamp

### OpenRouter

- Proxy to multiple LLM providers
- OpenAI-compatible API
- Supports model switching without code changes
- Default: Claude 3 Haiku (fast, cheap)

## Scaling Considerations

### Current (MVP)

- Single Rails process
- Single Sidekiq worker
- SQLite-friendly article volume

### Growth Path

- Add Sidekiq workers for parallel analysis
- Add Redis cluster for job throughput
- Add read replicas for query load
- Consider moving raw payloads to S3 if storage becomes an issue
- Add caching layer for trend queries
