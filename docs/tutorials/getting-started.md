# Getting Started

This tutorial walks you through setting up News Digest and fetching your first articles.

## Prerequisites

You'll need:

- Ruby 3.4+ installed
- Docker and Docker Compose
- A [NewsAPI.ai](https://newsapi.ai/) account
- An [OpenRouter](https://openrouter.ai/) account (for calm summaries)

## Step 1: Clone and Install

```bash
git clone <repo-url>
cd news-digest
bundle install
```

## Step 2: Start Services

The app uses PostgreSQL for data and Redis for background jobs. Start them with Docker:

```bash
docker-compose up -d
```

Verify they're running:

```bash
docker-compose ps
```

You should see `postgres` and `redis` containers running.

## Step 3: Configure Credentials

Edit Rails encrypted credentials:

```bash
EDITOR="code --wait" bin/rails credentials:edit --environment development
```

Add your API keys:

```yaml
news_api_ai:
  key: your_newsapi_ai_key_here

openrouter:
  api_key: your_openrouter_key_here
```

## Step 4: Setup Database

Create and migrate the database:

```bash
bundle exec rails db:create db:migrate
```

## Step 5: Fetch Your First Articles

Open a Rails console or use the runner:

```bash
bundle exec rails runner 'result = FetchArticlesJob.perform_now(country: "us"); puts "Fetched #{result[:stored]} articles"'
```

You should see something like:

```
Fetched 50 articles
```

Articles are automatically enriched with entities from the API response (people, organizations, places, categories).

## Step 6: Generate Calm Summaries

The fetch job automatically queues summary generation. If you want to process them synchronously:

```bash
bundle exec rails runner '
Article.without_summary.find_each do |article|
  print "."
  GenerateCalmSummaryJob.perform_now(article.id)
end
puts "\nDone!"
'
```

## Step 7: Explore the Results

See your calm news summaries:

```bash
bundle exec rails runner '
Article.with_summary.recent.limit(10).each do |article|
  puts "[#{article.category&.name}] #{article.calm_summary&.summary}"
  puts "  people: #{article.people.pluck(:name).join(", ")}"
  puts
end
'
```

Example output:

```
[business] Ripple CEO predicts Bitcoin will reach $180,000 by 2026, citing institutional interest.
  people: brad garlinghouse, richard teng, lily liu

[world] Markets recover as IT and auto sectors show strength despite currency concerns.
  people:
```

## Step 8: Check Entities

See what entities were extracted:

```bash
bundle exec rails runner '
puts "Top people:"
Entity.people.joins(:article_entities).group(:id).order("count(*) desc").limit(5).each do |e|
  puts "  #{e.name}: #{e.articles.count} articles"
end

puts "\nTop organizations:"
Entity.organizations.joins(:article_entities).group(:id).order("count(*) desc").limit(5).each do |e|
  puts "  #{e.name}: #{e.articles.count} articles"
end

puts "\nCategories:"
Entity.categories.each do |e|
  puts "  #{e.name}: #{e.articles.count} articles"
end
'
```

## Step 9: Start the Web UI

```bash
bundle exec rails server
```

Visit http://localhost:3000 to see your calm news digest.

## Next Steps

- Read [How to Fetch Articles](../how-to/fetch-headlines.md) for country and count options
- Read [How to Analyze Articles](../how-to/analyze-articles.md) for re-analysis with different models
- Read [How to Query Trends](../how-to/query-trends.md) for entity analysis
- See [Architecture](../explanation/architecture.md) to understand how it all fits together

## Running the Test Suite

Verify everything works:

```bash
bundle exec rspec
```

All tests should pass.
