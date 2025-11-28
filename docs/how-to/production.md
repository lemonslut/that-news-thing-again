# How to Run in Production

## Docker Build

Build the production image:

```bash
docker build -t news-digest .
```

## Environment Variables

Required in production:

```
RAILS_ENV=production
RAILS_MASTER_KEY=<from config/master.key>
DATABASE_HOST=<postgres host>
DATABASE_USER=<postgres user>
DATABASE_PASSWORD=<postgres password>
DATABASE_NAME=news_production
REDIS_URL=redis://<redis host>:6379/0
NEWS_API_KEY=<your key>
OPENROUTER_API_KEY=<your key>
```

## Docker Compose (Production)

Create a `docker-compose.prod.yml`:

```yaml
services:
  web:
    build: .
    environment:
      - RAILS_ENV=production
      - RAILS_MASTER_KEY
      - DATABASE_HOST=postgres
      - DATABASE_USER=news
      - DATABASE_PASSWORD=news
      - REDIS_URL=redis://redis:6379/0
      - NEWS_API_KEY
      - OPENROUTER_API_KEY
    depends_on:
      - postgres
      - redis
    ports:
      - "80:80"

  worker:
    build: .
    command: bundle exec sidekiq
    environment:
      - RAILS_ENV=production
      - RAILS_MASTER_KEY
      - DATABASE_HOST=postgres
      - DATABASE_USER=news
      - DATABASE_PASSWORD=news
      - REDIS_URL=redis://redis:6379/0
      - NEWS_API_KEY
      - OPENROUTER_API_KEY
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: news
      POSTGRES_PASSWORD: news
      POSTGRES_DB: news_production
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

## Run Migrations

```bash
docker-compose -f docker-compose.prod.yml run web bundle exec rails db:migrate
```

## Start Services

```bash
docker-compose -f docker-compose.prod.yml up -d
```

## Schedule Jobs

Use cron or a scheduler to periodically fetch headlines:

```bash
# Example cron entry (every hour)
0 * * * * docker-compose -f docker-compose.prod.yml run web bundle exec rails runner 'FetchHeadlinesJob.perform_now(country: "us")'
```

## Monitoring

Check Sidekiq:

```bash
docker-compose -f docker-compose.prod.yml logs worker
```

Check web logs:

```bash
docker-compose -f docker-compose.prod.yml logs web
```

## Health Check

Add a health endpoint or check article counts:

```bash
docker-compose -f docker-compose.prod.yml run web bundle exec rails runner 'puts Article.count'
```
