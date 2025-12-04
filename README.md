# News Digest

A calm news aggregation and analysis pipeline. Fetches articles with full bodies and pre-extracted entities from NewsAPI.ai, then generates whispered-style summaries for peaceful news consumption.

## What it does

- **Fetches** articles from NewsAPI.ai with full content and pre-extracted entities
- **Extracts** people, organizations, places, and categories from API response
- **Generates** calm, simple summaries — no sensationalism, just what happened
- **Tracks** trends over time via entities and categories

## Quick Start

```bash
# Start services
docker-compose up -d

# Install dependencies
bundle install

# Setup database
bundle exec rails db:create db:migrate

# Fetch some news
bundle exec rails runner 'FetchArticlesJob.perform_now(country: "us")'

# See what you've got
bundle exec rails runner 'Article.recent.limit(5).each { |a| puts "[#{a.category&.name}] #{a.title}" }'
```

## Requirements

- Ruby 3.4+
- PostgreSQL 16+
- Redis 7+
- Docker & Docker Compose (for local services)

## Configuration

API keys are stored in Rails encrypted credentials:

```bash
# Edit development credentials
EDITOR="code --wait" bin/rails credentials:edit --environment development
```

Required keys: `news_api_ai.key`, `openrouter.api_key`

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
