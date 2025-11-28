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

Now run the LLM analysis on the articles you fetched:

```bash
bundle exec rails runner '
Article.unanalyzed.find_each do |article|
  print "."
  AnalyzeArticleJob.perform_now(article.id)
end
puts "\nDone! Analyzed #{ArticleAnalysis.count} articles."
'
```

## Step 7: Explore the Results

See your calm news summaries:

```bash
bundle exec rails runner '
ArticleAnalysis.recent.limit(10).each do |analysis|
  puts "[#{analysis.category}] #{analysis.calm_summary}"
  puts "  tags: #{analysis.tags.join(", ")}"
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

## Step 8: Check Trends

See what topics are trending:

```bash
bundle exec rails runner '
puts "Top tags:"
ArticleAnalysis.tag_counts.first(10).each { |tag, count| puts "  #{tag}: #{count}" }
puts
puts "Categories:"
ArticleAnalysis.category_counts.each { |cat, count| puts "  #{cat}: #{count}" }
'
```

## Next Steps

- Read [How to Fetch Headlines](../how-to/fetch-headlines.md) for filtering options
- Read [How to Query Trends](../how-to/query-trends.md) for time-based analysis
- See [Architecture](../explanation/architecture.md) to understand how it all fits together

## Running the Test Suite

Verify everything works:

```bash
bundle exec rspec
```

All tests should pass.
