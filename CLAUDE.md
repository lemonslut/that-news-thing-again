# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Start services (PostgreSQL, Redis)
docker-compose up -d

# Run all tests
bundle exec rspec

# Run a single test file
bundle exec rspec spec/services/news_api/client_spec.rb

# Run a single test by line number
bundle exec rspec spec/models/article_spec.rb:27

# Rails console
bundle exec rails c

# NewsAPI exploration console (client pre-loaded)
bundle exec rake news_api:console

# Lint
bundle exec rubocop

# Start web + worker
overmind start -f Procfile.dev
```

## Architecture

News aggregation pipeline with separated LLM analysis concerns:

```
NewsAPI → NewsApi::Client → FetchHeadlinesJob → Article (PostgreSQL)
                                                    ↓
                              ┌─────────────────────┴─────────────────────┐
                              ↓                                           ↓
               ExtractEntitiesJob                          GenerateCalmSummaryJob
                              ↓                                           ↓
               ArticleEntityExtraction                        ArticleCalmSummary
                              ↓
                           Entity ←──── ArticleEntity (canonical link)
```

**Separated concerns design:**
- `Article` — pristine NewsAPI data with JSONB `raw_payload`
- `Entity` — normalized entities (all lowercase): people, organizations, places, tags, categories, publishers, authors
- `ArticleEntity` — canonical article↔entity relationship
- `ArticleEntityExtraction` — audit trail for entity extraction (prompt, model, timestamp)
- `ArticleCalmSummary` — calm summary with prompt/model provenance

**Services in `app/services/`:**
- `NewsApi::Client` — HTTP wrapper for NewsAPI, uses Faraday
- `Completions::Client` — generic LLM wrapper via OpenRouter (OpenAI-compatible)

**Jobs in `app/jobs/`:**
- `FetchHeadlinesJob` — Idempotent (upserts by URL), enqueues extraction + summary jobs
- `ExtractEntitiesJob` — Extracts entities with its own prompt, normalizes names to lowercase
- `GenerateCalmSummaryJob` — Generates calm summaries with its own prompt

**Scheduling:** Jobs are scheduled via sidekiq-scheduler (see `config/sidekiq.yml`). Headlines fetched hourly.

**Key scopes:**
- `Article.with_entities` / `Article.without_entities`
- `Article.with_summary` / `Article.without_summary`
- `Article.in_category(cat)` — Articles with category entity
- `Entity.of_type(type)` — Filter entities by type

## Environment

Secrets are stored in Rails encrypted credentials (per-environment):

```bash
# Edit development credentials
EDITOR="code --wait" bin/rails credentials:edit --environment development

# Edit production credentials
EDITOR="code --wait" bin/rails credentials:edit --environment production
```

Keys: `database.password`, `news_api.key`, `openrouter.api_key`, `sidekiq.web_password`

Database defaults to user `news` at localhost (see `config/database.yml`).

## Testing

Uses RSpec with WebMock. VCR cassettes in `spec/cassettes/` for NewsAPI. LLM calls are mocked in tests.

## Deployment

Uses Kamal for production deployment. See `config/deploy.yml` for configuration and `docs/how-to/production.md` for full instructions.

```bash
# Deploy
kamal deploy

# View logs
kamal logs

# Rails console on production
kamal console
```
