# Jobs Reference

## FetchHeadlinesJob

Fetches headlines from NewsAPI and stores them. Enqueues entity extraction and summary generation for each article.

### Location

`app/jobs/fetch_headlines_job.rb`

### Queue

`default`

### Arguments

```ruby
FetchHeadlinesJob.perform_now(country: "us", category: nil)
FetchHeadlinesJob.perform_later(country: "us", category: nil)
```

- `country` — 2-letter ISO code (default: "us")
- `category` — Optional category filter

### Returns

```ruby
{ stored: 15, skipped: 5, total: 20 }
```

- `stored` — New articles saved
- `skipped` — Duplicates or invalid articles
- `total` — Total articles in API response

### Behavior

1. Calls `NewsApi::Client#top_headlines`
2. Iterates articles, skipping those with blank title/URL
3. Uses `Article.upsert_from_news_api` to create or update
4. Enqueues `ExtractEntitiesJob` and `GenerateCalmSummaryJob` for each article
5. Logs results

### Example

```ruby
# Synchronous
result = FetchHeadlinesJob.perform_now(country: "us")
puts "Stored #{result[:stored]} articles"

# Asynchronous (requires Sidekiq)
FetchHeadlinesJob.perform_later(country: "gb", category: "technology")
```

---

## ExtractEntitiesJob

Extracts entities from an article using LLM.

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
# Synchronous
ExtractEntitiesJob.perform_now(article.id)

# With custom model
ExtractEntitiesJob.perform_now(article.id, model: "openai/gpt-4o")

# Process all unextracted articles
Article.without_entities.find_each do |article|
  ExtractEntitiesJob.perform_later(article.id)
end
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
