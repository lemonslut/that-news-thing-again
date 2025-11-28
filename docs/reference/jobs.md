# Jobs Reference

## FetchHeadlinesJob

Fetches headlines from NewsAPI and stores them.

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
4. Logs results

### Example

```ruby
# Synchronous
result = FetchHeadlinesJob.perform_now(country: "us")
puts "Stored #{result[:stored]} articles"

# Asynchronous (requires Sidekiq)
FetchHeadlinesJob.perform_later(country: "gb", category: "technology")
```

---

## AnalyzeArticleJob

Analyzes an article using LLM and stores the result.

### Location

`app/jobs/analyze_article_job.rb`

### Queue

`default`

### Arguments

```ruby
AnalyzeArticleJob.perform_now(article_id, model: nil)
AnalyzeArticleJob.perform_later(article_id, model: nil)
```

- `article_id` — ID of Article to analyze
- `model` — Optional LLM model (default: claude-3-haiku)

### Returns

`nil` (creates ArticleAnalysis record)

### Behavior

1. Finds Article by ID
2. Skips if analysis already exists
3. Calls `Completions::Client#analyze_article`
4. Creates ArticleAnalysis record
5. Logs result

### Example

```ruby
# Synchronous
AnalyzeArticleJob.perform_now(article.id)

# With custom model
AnalyzeArticleJob.perform_now(article.id, model: "openai/gpt-4o")

# Asynchronous batch
Article.unanalyzed.find_each do |article|
  AnalyzeArticleJob.perform_later(article.id)
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
