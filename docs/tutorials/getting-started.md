# Getting Started

This tutorial walks you through setting up News Digest and fetching your first analyzed articles.

## Prerequisites

You'll need:

- Ruby 3.4+ installed
- Docker and Docker Compose
- A [NewsAPI](https://newsapi.org/) account (free tier works)
- An [OpenRouter](https://openrouter.ai/) account

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

## Step 3: Configure Environment

Copy the example environment file:

```bash
cp .env.example .env
```

Edit `.env` and add your API keys:

```
NEWS_API_KEY=your_newsapi_key_here
OPENROUTER_API_KEY=your_openrouter_key_here
```

## Step 4: Setup Database

Create and migrate the database:

```bash
bundle exec rails db:create db:migrate
```

## Step 5: Fetch Your First Headlines

Open a Rails console or use the runner:

```bash
bundle exec rails runner 'result = FetchHeadlinesJob.perform_now(country: "us"); puts "Fetched #{result[:stored]} articles"'
```

You should see something like:

```
Fetched 20 articles
```

## Step 6: Analyze Articles

Now run the entity extraction and summary generation on the articles you fetched:

```bash
bundle exec rails runner '
Article.without_entities.find_each do |article|
  print "."
  ExtractEntitiesJob.perform_now(article.id)
  GenerateCalmSummaryJob.perform_now(article.id)
end
puts "\nDone! Processed #{Article.with_entities.count} articles."
'
```

## Step 7: Explore the Results

See your calm news summaries:

```bash
bundle exec rails runner '
Article.with_entities.recent.limit(10).each do |article|
  puts "[#{article.category&.name}] #{article.calm_summary&.summary}"
  puts "  tags: #{article.tags.pluck(:name).join(", ")}"
  puts
end
'
```

Example output:

```
[world] A fire in Hong Kong has killed at least 44 people, with rescue efforts ongoing.
  tags: fire, hong-kong, casualties

[politics] Congress debates new election legislation.
  tags: election, senate, voting
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

- Read [How to Fetch Headlines](../how-to/fetch-headlines.md) for filtering options
- Read [How to Analyze Articles](../how-to/analyze-articles.md) for model options
- Read [How to Query Trends](../how-to/query-trends.md) for entity analysis
- See [Architecture](../explanation/architecture.md) to understand how it all fits together

## Running the Test Suite

Verify everything works:

```bash
bundle exec rspec
```

All tests should pass.
