# Configuration Reference

## Environment Variables

### Required

| Variable | Description |
|----------|-------------|
| `NEWS_API_KEY` | NewsAPI.org API key |
| `OPENROUTER_API_KEY` | OpenRouter API key |

### Database

| Variable | Default | Description |
|----------|---------|-------------|
| `DATABASE_HOST` | `localhost` | PostgreSQL host |
| `DATABASE_USER` | `news` | PostgreSQL username |
| `DATABASE_PASSWORD` | `news` | PostgreSQL password |
| `DATABASE_NAME` | `news_<env>` | Database name (production only) |

### Redis

| Variable | Default | Description |
|----------|---------|-------------|
| `REDIS_URL` | `redis://localhost:6379/0` | Redis connection URL |

### Rails

| Variable | Default | Description |
|----------|---------|-------------|
| `RAILS_ENV` | `development` | Rails environment |
| `RAILS_MASTER_KEY` | — | Master key for credentials (production) |
| `RAILS_MAX_THREADS` | `5` | Puma/database connection pool size |

### OpenRouter

| Variable | Default | Description |
|----------|---------|-------------|
| `APP_URL` | `http://localhost:3000` | App URL for OpenRouter headers |

## Files

### .env

Local environment variables (not committed):

```
NEWS_API_KEY=your_key
OPENROUTER_API_KEY=your_key
```

### .env.example

Template for environment variables (committed):

```
NEWS_API_KEY=your_api_key_here
OPENROUTER_API_KEY=your_openrouter_key_here
```

### config/database.yml

PostgreSQL configuration:

```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  host: <%= ENV.fetch("DATABASE_HOST", "localhost") %>
  username: <%= ENV.fetch("DATABASE_USER", "news") %>
  password: <%= ENV.fetch("DATABASE_PASSWORD", "news") %>
```

### config/initializers/sidekiq.rb

Sidekiq Redis configuration:

```ruby
Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
end
```

### config/initializers/openai.rb

OpenRouter configuration:

```ruby
OpenAI.configure do |config|
  config.access_token = ENV.fetch("OPENROUTER_API_KEY", nil)
  config.uri_base = "https://openrouter.ai/api/v1"
  config.extra_headers = {
    "HTTP-Referer" => ENV.fetch("APP_URL", "http://localhost:3000"),
    "X-Title" => "NewsDigest"
  }
end
```

## Docker Compose

### Development (docker-compose.yml)

```yaml
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: news
      POSTGRES_PASSWORD: news
      POSTGRES_DB: news_development
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
```

## LLM Models

Default model: `anthropic/claude-3-haiku`

Override per-job:

```ruby
AnalyzeArticleJob.perform_now(article.id, model: "openai/gpt-4o-mini")
```

Available via OpenRouter:

- `anthropic/claude-3-haiku` — Fast, cheap
- `anthropic/claude-3-sonnet` — Better quality
- `anthropic/claude-3-opus` — Highest quality
- `openai/gpt-4o-mini` — OpenAI fast
- `openai/gpt-4o` — OpenAI quality

See [OpenRouter models](https://openrouter.ai/models) for full list.
