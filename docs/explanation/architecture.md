# Architecture Overview

## System Diagram

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  NewsAPI    │────▶│   Rails     │────▶│ PostgreSQL  │
└─────────────┘     │   App       │     └─────────────┘
                    │             │            │
┌─────────────┐     │  ┌───────┐  │     ┌──────┴──────┐
│ OpenRouter  │◀────│  │Sidekiq│  │     │  Articles   │
│  (LLM)      │     │  └───────┘  │     │  Entities   │
└─────────────┘     └──────┬──────┘     │  Summaries  │
                           │            └─────────────┘
                    ┌──────┴──────┐
                    │    Redis    │
                    └─────────────┘
```

## Data Flow

### 1. Fetch Headlines

```
NewsAPI ─── HTTP ───▶ NewsApi::Client ───▶ FetchHeadlinesJob ───▶ Article
                                                    │
                              ┌─────────────────────┴─────────────────────┐
                              ↓                                           ↓
                    ExtractEntitiesJob                      GenerateCalmSummaryJob
```

1. `FetchHeadlinesJob` is triggered (manually or scheduled)
2. `NewsApi::Client` makes HTTP request to NewsAPI
3. Response is parsed and each article is saved via `Article.upsert_from_news_api`
4. Duplicates are detected by unique URL constraint
5. `ExtractEntitiesJob` and `GenerateCalmSummaryJob` are enqueued

### 2. Extract Entities

```
Article ───▶ ExtractEntitiesJob ───▶ Completions::Client ───▶ OpenRouter
                                                                    │
                                                                    ↓
                   ArticleEntityExtraction ◀─────────────────── LLM Response
                           │
                           ↓
                        Entity ←──── ArticleEntity
```

1. `ExtractEntitiesJob` receives an article ID
2. `Completions::Client` sends article data to LLM with entity extraction prompt
3. LLM returns structured JSON (category, tags, people, orgs, places)
4. `ArticleEntityExtraction` record created (audit trail)
5. `Entity` records created/found (normalized to lowercase)
6. `ArticleEntity` links created (canonical relationship)

### 3. Generate Summary

```
Article ───▶ GenerateCalmSummaryJob ───▶ Completions::Client ───▶ OpenRouter
                                                                       │
                                                                       ↓
                     ArticleCalmSummary ◀────────────────────── LLM Response
```

1. `GenerateCalmSummaryJob` receives an article ID
2. `Completions::Client` sends article data to LLM with summary prompt
3. LLM returns calm summary
4. `ArticleCalmSummary` record created

### 4. Query & Display

```
Article ───▶ article.entities ───▶ UI
        ───▶ article.calm_summary ───▶ UI
        ───▶ Article.in_category(cat) ───▶ Filtered list
```

Articles and entities are queried via ActiveRecord for:
- Entity relationships (people, places, organizations in an article)
- Category filtering (articles in "politics", "sports", etc.)
- Trend analysis (which entities appear most frequently)

## Components

### Models

**Article** — Source of truth for news content
- Stores raw NewsAPI payload in JSONB
- Indexed by URL (unique), published_at, source_name

**Entity** — Normalized entity storage
- All names lowercase for deduplication
- Types: person, organization, place, tag, category, publisher, author
- Unique constraint on (entity_type, name)

**ArticleEntity** — Canonical article↔entity relationship
- The "truth" of what entities an article has
- Independent of which extraction found them

**ArticleEntityExtraction** — Audit trail for extractions
- Records when, with which model/prompt, entities were extracted
- Links to entities via join table for provenance

**ArticleCalmSummary** — Summary storage
- Multiple summaries possible per article (different models/prompts)
- UI shows most recent

**Prompt** — Versioned prompts
- Separate prompts for "entity_extraction" and "calm_summary"
- Active flag for current production prompt

### Services

**NewsApi::Client** — Thin wrapper around NewsAPI
- Handles authentication, error mapping
- Uses Faraday for HTTP

**Completions::Client** — Generic LLM interface via OpenRouter
- Uses ruby-openai gem pointed at OpenRouter
- Extracts JSON from potentially chatty LLM responses
- No domain-specific methods (jobs handle prompts)

### Jobs

**FetchHeadlinesJob** — Pulls from NewsAPI
- Idempotent (upserts by URL)
- Enqueues extraction and summary jobs
- Returns stats for monitoring

**ExtractEntitiesJob** — Runs entity extraction
- Has its own prompt (configurable)
- Normalizes all entity names to lowercase
- Creates both extraction record and canonical entity links

**GenerateCalmSummaryJob** — Runs summary generation
- Has its own prompt (configurable)
- Creates summary record with provenance

## Storage

### PostgreSQL

Primary data store. Chosen because:
- JSONB for flexible payload storage with query capability
- Indexes on entity relationships for fast queries
- Reliable, well-understood, easy to backup

### Redis

Sidekiq job queue backend. Stores:
- Pending jobs
- Job metadata
- No persistent application data

## Design Decisions

### Separated Concerns

Entity extraction and summary generation are independent jobs because:
- Different prompts, different purposes
- Can iterate on one without affecting the other
- Can run with different models
- Can re-run independently

### Entity Normalization

All entity names are lowercase because:
- "Apple" and "apple" should be the same entity
- Simpler deduplication
- Consistent display (UI can titlecase if needed)

### Canonical vs Provenance

Two relationships between articles and entities:
- `ArticleEntity` — canonical "this article has this entity"
- `ArticleEntityExtractionEntity` — "this extraction found this entity"

This allows:
- Simple queries (`article.entities`)
- Audit trail (which extraction found what)
- Re-running extractions without losing history

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
