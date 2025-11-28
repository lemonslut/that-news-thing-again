# How to Fetch Headlines

## Basic Fetch

Fetch top headlines from a country:

```ruby
FetchHeadlinesJob.perform_now(country: "us")
```

## Filter by Category

NewsAPI supports these categories: `business`, `entertainment`, `general`, `health`, `science`, `sports`, `technology`.

```ruby
FetchHeadlinesJob.perform_now(country: "us", category: "technology")
```

## Available Countries

Use 2-letter ISO codes: `us`, `gb`, `ca`, `au`, `de`, `fr`, etc.

```ruby
FetchHeadlinesJob.perform_now(country: "gb")
```

## Fetch Multiple Categories

Run multiple jobs:

```ruby
%w[politics technology health business].each do |category|
  FetchHeadlinesJob.perform_now(country: "us", category: category)
end
```

## Run Asynchronously

Queue jobs for Sidekiq:

```ruby
FetchHeadlinesJob.perform_later(country: "us")
```

Make sure Sidekiq is running:

```bash
bundle exec sidekiq
```

## Schedule Regular Fetches

Add to `config/recurring.yml` or use a cron-like scheduler:

```ruby
# In a scheduled task or cron job
FetchHeadlinesJob.perform_later(country: "us")
```

## Check Results

```ruby
# How many articles do we have?
Article.count

# Recent articles
Article.recent.limit(5).pluck(:title)

# Articles from today
Article.published_after(Time.current.beginning_of_day).count
```

## Direct Client Access

For exploration, use the client directly:

```ruby
client = NewsApi::Client.new
result = client.top_headlines(country: "us", category: "science")
result["articles"].each { |a| puts a["title"] }
```

Or use the rake task:

```bash
bundle exec rake news_api:console
# Then: client.top_headlines(country: "us")
```
