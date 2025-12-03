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

News aggregation pipeline with LLM analysis:

```
NewsAPI → NewsApi::Client → FetchHeadlinesJob → Article (PostgreSQL)
                                                    ↓
Article → AnalyzeArticleJob → Completions::Client → OpenRouter → ArticleAnalysis
```

**Two-table design:** `Article` stores pristine NewsAPI data with JSONB `raw_payload`. `ArticleAnalysis` stores LLM-generated metadata (category, tags, entities, political_lean, calm_summary). One-to-one relationship, separated to allow re-analysis with different models.

**Services in `app/services/`:**
- `NewsApi::Client` — HTTP wrapper for NewsAPI, uses Faraday
- `Completions::Client` — LLM wrapper via OpenRouter (OpenAI-compatible), extracts JSON from responses

**Jobs in `app/jobs/`:**
- `FetchHeadlinesJob` — Idempotent (upserts by URL), accepts `country:` and `category:`
- `AnalyzeArticleJob` — Idempotent (skips existing analysis), accepts `model:` override
- `AnalyzeUnanalyzedArticlesJob` — Batch enqueues analysis for unanalyzed articles

**Scheduling:** Jobs are scheduled via sidekiq-scheduler (see `config/sidekiq.yml`). Headlines fetched hourly, analysis runs 15 minutes later.

**Key scopes:**
- `Article.unanalyzed` — Articles without analysis
- `ArticleAnalysis.with_tag(tag)` — GIN-indexed tag query
- `ArticleAnalysis.tag_counts(since:)` — Trend analysis

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
