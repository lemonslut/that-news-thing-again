# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Start services (PostgreSQL, Redis)
docker-compose up -d

# Run all tests
bundle exec rspec

# Run a single test file
bundle exec rspec spec/services/news_api_ai/client_spec.rb

# Run a single test by line number
bundle exec rspec spec/models/article_spec.rb:27

# Rails console
bundle exec rails c

# NewsAPI.ai exploration console (client pre-loaded)
bundle exec rake news_api:console

# Lint
bundle exec rubocop

# Start web + worker
overmind start -f Procfile.dev
```

## Architecture

News aggregation pipeline with pre-extracted entities from NewsAPI.ai:

```
NewsAPI.ai → NewsApiAi::Client → FetchArticlesJob → Article (PostgreSQL)
                                        ↓                    ↓
                                  Entity extraction    GenerateCalmSummaryJob
                                  (from API concepts)        ↓
                                        ↓             ArticleCalmSummary
                                     Entity ←──── ArticleEntity (canonical link)
```

**Separated concerns design:**
- `Article` — NewsAPI.ai data with JSONB `raw_payload` (includes full body)
- `Entity` — normalized entities (all lowercase): people, organizations, places, tags, categories, publishers, authors
- `ArticleEntity` — canonical article↔entity relationship
- `ArticleEntityExtraction` — audit trail for LLM entity extraction (legacy/reanalysis)
- `ArticleCalmSummary` — calm summary with prompt/model provenance

**Services in `app/services/`:**
- `NewsApiAi::Client` — HTTP wrapper for NewsAPI.ai (Event Registry), uses Faraday
- `Completions::Client` — generic LLM wrapper via OpenRouter (OpenAI-compatible)

**Jobs in `app/jobs/`:**
- `FetchArticlesJob` — Fetches from NewsAPI.ai, extracts entities inline from API concepts
- `ExtractEntitiesJob` — LLM-based entity extraction (for legacy articles or reanalysis)
- `GenerateCalmSummaryJob` — Generates calm summaries with its own prompt

**Scheduling:** Jobs are scheduled via sidekiq-scheduler (see `config/sidekiq.yml`). Articles fetched hourly.

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

Keys: `database.password`, `news_api_ai.key`, `openrouter.api_key`, `sidekiq.web_password`

Database defaults to user `news` at localhost (see `config/database.yml`).

## Testing

Uses RSpec with WebMock. VCR cassettes in `spec/cassettes/` for NewsAPI.ai. LLM calls are mocked in tests.

## Deployment

Uses Kamal for production deployment. See `config/deploy.yml` for configuration and `docs/how-to/production.md` for full instructions.

```bash
# Deploy (requires env vars)
KAMAL_REGISTRY_PASSWORD='...' POSTGRES_PASSWORD='...' kamal deploy

# View logs
kamal logs

# Rails console on production
kamal console

# Run rake task in production
kamal app exec "bundle exec rake users:bootstrap"
```

### Production Server Inspection

SSH as root to `news.lemonslut.com`:

```bash
# List running containers
ssh root@news.lemonslut.com "docker ps --format '{{.Names}}'"

# Get env vars from a container (e.g., postgres password)
ssh root@news.lemonslut.com "docker inspect news-digest-postgres --format '{{range .Config.Env}}{{println .}}{{end}}'"

# Get registry credentials (base64 encoded)
ssh root@news.lemonslut.com "cat ~/.docker/config.json"

# Decode the auth token
echo "base64string" | base64 -d
# Output: username:password
```

### Kamal Secrets

Secrets are loaded from environment variables via `.kamal/secrets`:
- `KAMAL_REGISTRY_PASSWORD` — GitHub PAT with `write:packages` scope
- `POSTGRES_PASSWORD` — Database password (must match credentials)
- `RAILS_MASTER_KEY` — Read automatically from `config/credentials/production.key`

## Authentication

Simple session-based auth with bearer token bypass for scripting.

```bash
# Create/reset the default user in production
kamal app exec "bundle exec rake users:bootstrap"
# Outputs: email, password, and API token

# API access with bearer token
curl -H "Authorization: Bearer TOKEN" https://news.lemonslut.com/articles
```

Web login at `/session/new`. No password reset (users managed via rake task).
