# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Start services (PostgreSQL, Redis, InfluxDB)
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

# Check Sidekiq queue depths
bundle exec rake sidekiq:queue_depth

# Lint
bundle exec rubocop

# Start web + worker + CSS watcher
overmind start -f Procfile.dev

# Build CSS manually (one-time)
yarn build:css

# Install frontend dependencies
yarn install
```

## Frontend

Uses Tailwind CSS v3 with [Sira UI](https://sira.riazer.com/) component library.

**Key files:**
- `tailwind.config.js` — Tailwind + Sira plugin config
- `app/assets/stylesheets/application.tailwind.css` — CSS entry point
- `app/assets/builds/application.css` — compiled output (gitignored)
- `package.json` — Node dependencies

**Development:** `overmind start -f Procfile.dev` runs the CSS watcher alongside web/worker.

**Production:** Docker build runs `yarn install` + `rails assets:precompile` which triggers `yarn build:css`.

## Architecture

News aggregation pipeline with LLM-powered analysis:

```
NewsAPI.ai → FetchArticlesJob → Article (PostgreSQL)
                   ↓
         ┌────────┴────────┐
         ↓                 ↓
GenerateFactualSummaryJob  NerExtractionJob
         ↓                 ↓
   Article#factual_summary  ArticleAnalysis (ner_extraction)
                                  ↓
                           ExtractSubjectsJob
                                  ↓
                           ArticleSubject → Concept
```

**Core models:**
- `Article` — NewsAPI.ai data with JSONB `raw_payload` (includes full body)
- `Concept` — normalized entities: people, organizations, places, tags, categories
- `ArticleSubject` — article↔concept relationship with relevance scoring
- `ArticleAnalysis` — LLM analysis results (only `ner_extraction` type is active)

**Services in `app/services/`:**
- `NewsApiAi::Client` — HTTP wrapper for NewsAPI.ai (Event Registry), uses Faraday
- `Completions::Client` — LLM wrapper via OpenRouter (OpenAI-compatible), default model: `openai/gpt-oss-120b`

**Jobs in `app/jobs/`:**
- `FetchArticlesJob` — Fetches from NewsAPI.ai, enqueues analysis pipeline per article
- `GenerateFactualSummaryJob` — Generates factual summaries via LLM
- `NerExtractionJob` — Extracts named entities via LLM
- `ExtractSubjectsJob` — Extracts subject concepts from NER results
- `CaptureTrendsJob` / `CaptureDailyTrendsJob` — Trend tracking
- `CleanupTrendsJob` — Prunes old trend data

**Scheduling:** Jobs are scheduled via sidekiq-scheduler (see `config/sidekiq.yml`). Articles fetched hourly.

**Design principle:** Articles flow through the pipeline individually — each article enqueues its own analysis jobs rather than batch processing.

## Environment

Secrets are stored in Rails encrypted credentials (per-environment):

```bash
# Edit development credentials
EDITOR="code --wait" bin/rails credentials:edit --environment development

# Edit production credentials
EDITOR="code --wait" bin/rails credentials:edit --environment production
```

Keys: `database.password`, `news_api_ai.key`, `openrouter.api_key`, `sidekiq.web_password`, `influxdb.token`

Database defaults to user `news` at localhost (see `config/database.yml`).

## Metrics & Monitoring

**InfluxDB 3 Core** stores Rails/Sidekiq metrics via `influxdb-rails` gem:
- Controller response times, SQL queries, view rendering
- ActiveJob execution times, success/failure states, exception classes
- Internal only at `news-digest-influxdb:8181`

**Grafana** at https://grafana.lemonslut.com visualizes metrics (user: `admin`).

**Note:** `config/initializers/influxdb_activejob_patch.rb` patches influxdb-rails to correctly detect failed jobs via `payload[:exception]` instead of `payload[:aborted]`.

Example Grafana queries (InfluxDB SQL):
```sql
-- Web request latency p50/p95
SELECT date_bin('1 minute', time) as time,
  approx_percentile_cont(CAST(controller AS DOUBLE), 0.5) as p50_ms,
  approx_percentile_cont(CAST(controller AS DOUBLE), 0.95) as p95_ms
FROM rails WHERE hook = 'process_action'
  AND time >= $__timeFrom AND time <= $__timeTo
GROUP BY 1 ORDER BY 1

-- Job throughput by class (jobs/min, 10s buckets)
SELECT date_bin('10 seconds', time) as time, job,
  COUNT(*) * 6.0 as jobs_per_min
FROM rails WHERE hook = 'perform'
  AND time >= $__timeFrom AND time <= $__timeTo
GROUP BY 1, job ORDER BY 1

-- Failed jobs by exception class
SELECT date_bin('1 minute', time) as time, job, class_name, COUNT(*) as failures
FROM rails WHERE hook = 'perform' AND state = 'failed'
  AND time >= $__timeFrom AND time <= $__timeTo
GROUP BY 1, job, class_name ORDER BY 1
```

## Testing

Uses RSpec with WebMock. VCR cassettes in `spec/cassettes/` for NewsAPI.ai. LLM calls are mocked in tests.

## Deployment

Uses Kamal for production deployment. See `config/deploy.yml` for configuration.

```bash
# Deploy (requires env vars)
KAMAL_REGISTRY_PASSWORD='...' RAILS_MASTER_KEY='...' POSTGRES_PASSWORD='...' bundle exec kamal deploy

# View logs
kamal logs

# Rails console on production
kamal console

# Run rake task in production
kamal app exec "bundle exec rake users:bootstrap"

# Manage accessories
kamal accessory boot influxdb
kamal accessory boot grafana
kamal accessory exec influxdb "influxdb3 create token --admin"

# Configure Grafana proxy (after booting accessory)
ssh root@news.lemonslut.com "docker exec kamal-proxy kamal-proxy deploy news-digest-grafana --target news-digest-grafana:3000 --host grafana.lemonslut.com --tls"
```

### Production Server Inspection

SSH as root to `news.lemonslut.com`:

```bash
# List running containers
ssh root@news.lemonslut.com "docker ps --format '{{.Names}}'"

# Check Sidekiq queues
ssh root@news.lemonslut.com "docker exec news-digest-job-... bundle exec rake sidekiq:queue_depth"
```

### Kamal Secrets

Secrets are loaded from environment variables via `.kamal/secrets`:
- `KAMAL_REGISTRY_PASSWORD` — GitHub PAT with `write:packages` scope
- `POSTGRES_PASSWORD` — Database password (must match credentials)
- `RAILS_MASTER_KEY` — Read automatically from `config/credentials/production.key`
- `GF_SECURITY_ADMIN_PASSWORD` — Grafana admin password

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
