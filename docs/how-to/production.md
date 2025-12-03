# How to Run in Production

This project uses [Kamal](https://kamal-deploy.org) for deployment.

## Prerequisites

- A server with Docker installed (Ubuntu 22.04+ recommended)
- SSH access to your server as root or a user with Docker permissions
- A container registry account (GitHub Container Registry, Docker Hub, etc.)
- A domain name pointed at your server

## Configuration

### 1. Update deploy.yml

Edit `config/deploy.yml` with your details:

```yaml
# Your container image location
image: ghcr.io/your-username/news-digest

# Your server IP(s)
servers:
  web:
    - YOUR_SERVER_IP
  job:
    hosts:
      - YOUR_SERVER_IP

# Your domain
proxy:
  host: news.yourdomain.com

# Your registry credentials
registry:
  server: ghcr.io
  username: your-github-username
```

### 2. Credentials Setup

Secrets are stored in Rails encrypted credentials (`config/credentials/production.yml.enc`).

To edit production credentials:

```bash
EDITOR="code --wait" bin/rails credentials:edit --environment production
```

Required keys:

```yaml
secret_key_base: <generated automatically>

database:
  password: <strong random password>

news_api:
  key: <your newsapi.org key>

openrouter:
  api_key: <your openrouter.ai key>

sidekiq:
  web_password: <password for /sidekiq dashboard>
```

### 3. Set Environment Variables

Before deploying, export these environment variables locally:

```bash
export KAMAL_REGISTRY_PASSWORD=<github PAT with packages:write>
export RAILS_MASTER_KEY=<contents of config/credentials/production.key>
export POSTGRES_PASSWORD=<same value as database.password in credentials>
```

Note: `POSTGRES_PASSWORD` must match `database.password` in credentials — it's used by the Postgres container.

## Deployment

### First Deploy

```bash
# Set up accessories (Postgres, Redis) on your server
kamal accessory boot all

# Deploy the application
kamal setup
```

### Subsequent Deploys

```bash
kamal deploy
```

### Rolling Back

```bash
kamal rollback
```

## Operations

### View Logs

```bash
# Web server logs
kamal app logs

# Sidekiq worker logs
kamal app logs -r job

# Follow logs
kamal logs
```

### Rails Console

```bash
kamal console
```

### Database Console

```bash
kamal dbconsole
```

### Shell Access

```bash
kamal shell
```

### Run Rake Tasks

```bash
kamal app exec 'bin/rails db:migrate'
kamal app exec 'bin/rails runner "puts Article.count"'
```

## Scheduled Jobs

Jobs are scheduled automatically via sidekiq-scheduler. The schedule is defined in `config/sidekiq.yml`:

- **Fetch headlines**: Every hour (`:00`)
- **Analyze unanalyzed articles**: Every hour (`:15`)

No external cron needed.

## Monitoring

### Sidekiq Dashboard

Access the Sidekiq web UI at `https://your-domain.com/sidekiq`

- Username: `admin`
- Password: Value of `sidekiq.web_password` from credentials

The dashboard shows:
- Scheduled recurring jobs
- Queue status
- Failed jobs
- Worker activity

### Health Check

The `/up` endpoint returns 200 when the app is healthy:

```bash
curl https://your-domain.com/up
```

## Accessory Management

### Postgres

```bash
# View postgres logs
kamal accessory logs postgres

# Restart postgres
kamal accessory reboot postgres

# Backup database
kamal accessory exec postgres 'pg_dump -U news news_production' > backup.sql
```

### Redis

```bash
# View redis logs
kamal accessory logs redis

# Restart redis
kamal accessory reboot redis
```

## Troubleshooting

### Check container status

```bash
kamal details
```

### SSH to server

```bash
ssh root@YOUR_SERVER_IP
docker ps  # See running containers
```

### Force restart

```bash
kamal app boot
```

### Rebuild from scratch

```bash
kamal app remove
kamal accessory remove all
kamal setup
```
