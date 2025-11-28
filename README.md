# News Digest

A calm news aggregation and analysis pipeline. Fetches headlines, categorizes them with LLM analysis, and generates whispered-style summaries for peaceful news consumption.

## What it does

- **Fetches** headlines from NewsAPI
- **Analyzes** articles using LLM (via OpenRouter) for categorization, tagging, and entity extraction
- **Generates** calm, simple summaries — no sensationalism, just what happened
- **Tracks** trends over time via tags and categories

## Quick Start

```bash
# Start services
docker-compose up -d

# Install dependencies
bundle install

# Setup database
bundle exec rails db:create db:migrate

# Fetch some news
bundle exec rails runner 'FetchHeadlinesJob.perform_now(country: "us")'

# Analyze articles
bundle exec rails runner 'Article.unanalyzed.find_each { |a| AnalyzeArticleJob.perform_now(a.id) }'

# See what you've got
bundle exec rails runner 'ArticleAnalysis.recent.limit(5).each { |a| puts "[#{a.category}] #{a.calm_summary}" }'
```

## Requirements

- Ruby 3.4+
- PostgreSQL 16+
- Redis 7+
- Docker & Docker Compose (for local services)

## Configuration

Copy `.env.example` to `.env` and add your API keys:

```
NEWS_API_KEY=your_newsapi_key
OPENROUTER_API_KEY=your_openrouter_key
```

## Documentation

See the [docs/](docs/) directory:

- [Tutorial: Getting Started](docs/tutorials/getting-started.md)
- [How-to Guides](docs/how-to/)
- [Reference](docs/reference/)
- [Architecture & Design](docs/explanation/)

## Running Tests

```bash
bundle exec rspec
```

## License

MIT
