# Jobs Reference

## FetchArticlesJob

Fetches articles from NewsAPI.ai, stores them, extracts entities from the API response, and enqueues summary generation.

### Location

`app/jobs/fetch_articles_job.rb`

### Queue

`default`

### Arguments

```ruby
FetchArticlesJob.perform_now(country: "us", count: 50)
FetchArticlesJob.perform_later(country: "us", count: 50)
```

- `country` — 2-letter ISO code (default: "us"). Supported: us, gb, uk, ca, au, de, fr
- `count` — Number of articles to fetch (default: 50, max: 100)

### Returns

```ruby
{ stored: 15, skipped: 5, total: 20 }
```

- `stored` — New articles saved
- `skipped` — Duplicates or invalid articles
- `total` — Total articles in API response

### Behavior

1. Calls `NewsApiAi::Client#top_headlines`
2. Iterates articles, skipping those with blank title/URL
3. Uses `Article.upsert_from_news_api_ai` to create or update
4. Extracts entities directly from API concepts (no LLM call)
5. Enqueues `GenerateCalmSummaryJob` for each article
6. Logs results

### Entity Extraction

Entities are extracted inline from the API response:

- **Concepts** with type `person`, `org`, `loc` become person/organization/place entities
- **Categories** are extracted (e.g., `news/Business` → `business`)
- **Publisher** from article source
- **Author** from article authors

### Example

```ruby
# Synchronous
result = FetchArticlesJob.perform_now(country: "us")
puts "Stored #{result[:stored]} articles"

# Asynchronous (requires Sidekiq)
FetchArticlesJob.perform_later(country: "gb", count: 25)
```

---

## ExtractEntitiesJob

Extracts entities from an article using LLM. Used for re-analyzing articles or processing legacy articles without pre-extracted entities.

### Location

`app/jobs/extract_entities_job.rb`

### Queue

`default`

### Arguments

```ruby
ExtractEntitiesJob.perform_now(article_id, model: nil, prompt: nil)
ExtractEntitiesJob.perform_later(article_id, model: nil, prompt: nil)
```

- `article_id` — ID of Article to process
- `model` — Optional LLM model (default: claude-3-haiku)
- `prompt` — Optional Prompt record to use

### Returns

`nil` (creates ArticleEntityExtraction and Entity records)

### Behavior

1. Finds Article by ID
2. Calls LLM with entity extraction prompt
3. Creates ArticleEntityExtraction record
4. Creates/links Entity records (normalized to lowercase)
5. Creates ArticleEntity links (canonical relationship)
6. Logs result

### Entities Extracted

- `category` — Article category
- `tags` — Topic tags
- `people` — Person names
- `organizations` — Organization names
- `places` — Location names
- `publisher` — From article source_name
- `author` — From article author field

### Example

```ruby
# Re-analyze an article
ExtractEntitiesJob.perform_now(article.id)

# With custom model
ExtractEntitiesJob.perform_now(article.id, model: "openai/gpt-4o")
```

---

## GenerateCalmSummaryJob

Generates a calm summary for an article using LLM.

### Location

`app/jobs/generate_calm_summary_job.rb`

### Queue

`default`

### Arguments

```ruby
GenerateCalmSummaryJob.perform_now(article_id, model: nil, prompt: nil)
GenerateCalmSummaryJob.perform_later(article_id, model: nil, prompt: nil)
```

- `article_id` — ID of Article to process
- `model` — Optional LLM model (default: claude-3-haiku)
- `prompt` — Optional Prompt record to use

### Returns

`nil` (creates ArticleCalmSummary record)

### Behavior

1. Finds Article by ID
2. Calls LLM with calm summary prompt
3. Creates ArticleCalmSummary record with result
4. Logs result

### Example

```ruby
# Synchronous
GenerateCalmSummaryJob.perform_now(article.id)

# With custom model
GenerateCalmSummaryJob.perform_now(article.id, model: "anthropic/claude-3-sonnet")

# Process all articles without summaries
Article.without_summary.find_each do |article|
  GenerateCalmSummaryJob.perform_later(article.id)
end
```

---

## Running Sidekiq

Start the worker:

```bash
bundle exec sidekiq
```

Or use the Procfile:

```bash
overmind start -f Procfile.dev
# or
foreman start -f Procfile.dev
```

### Configuration

Redis connection in `config/initializers/sidekiq.rb`:

```ruby
Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
end
```
